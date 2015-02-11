################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class Plan < ActiveRecord::Base

  # we are protecting aasm state from mass assignment so the state machine can
  # manage transitions properly.
  attr_accessible :name, :plan_template_id, :release_manager_id, :release_date,
                  :release_id, :description, :plan_template_type, :stage_date,
                :plan_template_name, :plan_template_name_lookup_failed,
                :release_name, :release_name_lookup_failed, :aasm_event,
                :plan_template, :team_ids,:plan_template_type, :stage_date,
                :plan_template_name, :plan_template_name_lookup_failed,
                :aasm_event, :release, :release_manager, :release_attributes,
                :foreign_id, :project_server_id


  attr_accessor :plan_template_type, :stage_date,
                :plan_template_name, :plan_template_name_lookup_failed,
                :release_name, :release_name_lookup_failed, :aasm_event,
                :executable_event

  # normalize attributes by default does name and title
  normalize_attributes :description, :name, :foreign_id

  concerned_with :plan_state_machine
  concerned_with :plan_named_scopes
  concerned_with :plan_sortable

  # FIXME: The association dependencies noted below will not get triggered until plans
  # are converted to a proper pattern for deletion, since deleting is just an aasm_state
  # at the moment.  I have worked to destroy_all in the state transition for the associations
  # marked as destroy here, but remember anything new or different needs to be adjusted
  # there to avoid leaving stranded associations.

  # CHKME: This may be no longer needed after removal of release contents and change requests in 2.6
  has_many :integration_csvs, :dependent => :nullify

  has_many :plan_teams, :dependent => :destroy
  has_many :linked_items, :as => :target_holder, :dependent => :destroy
  has_many :members, :class_name => 'PlanMember', :dependent => :destroy
  has_many :requests, :through => :members
  has_many :runs, :dependent => :destroy
  has_many :stage_dates, :class_name => 'PlanStageDate', :dependent => :destroy
  has_many :teams, :through => :plan_teams
  has_many :tickets, :through => :linked_items, :as => :source_holder, :source => :source_holder, :source_type => 'Ticket'
  has_many :plan_env_app_dates

  # while plans use their plan_template for the authoritative list of their stages (a legacy of the early database design)
  # we are expanding our model to provide a plan_stage_instance that represents the instance of a plan stage and
  # a plan and provides a state machine
  has_many :plan_stage_instances, :dependent => :destroy
  has_many :constraints, :through => :plan_stage_instances

  # in order to scope environment routes (sets of environments by app) to plans, we need
  # an intermediate model called plan routes to make the assignment and own the particular
  # synchronization between the plan stages and the specific route_gates
  has_many :plan_routes, :dependent => :destroy
  has_many :routes, :through => :plan_routes

  has_many :queries, :dependent => :destroy

  belongs_to :plan_template
  belongs_to :release
  belongs_to :release_manager, :class_name => "User", :foreign_key => "release_manager_id"
  belongs_to :project_server

  # accept request attributes from forms or rest calls, including nullification
  accepts_nested_attributes_for :release, :allow_destroy => true,
    :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }

  # TODO: A bug in Arel causes case insensitive uniqueness to throw an error on plan creation through rest
  # under some conditions/databases.  Turning it off for now.  See https://github.com/binarylogic/authlogic/issues/360
  validates :name,
            :presence => true,
            :uniqueness => {:case_sensitive => true},
            :length => {:maximum => 255}
  validates :plan_template, :presence => true

  validates :project_server_id, :presence => true, :unless => Proc.new {|p| p.foreign_id.blank?}
  validate  :project_server_exists
  validate  :release_manager_exists

  validates :foreign_id,
            :length => {:maximum => 50},
            :uniqueness => {:scope => :project_server_id, :message => ' of the release ticket for the given integration has already been taken up.',
                            :unless => Proc.new {|p| p.aasm_state != "deleted"} },
            :allow_blank => true

  # looks for boolean failure flags on a restful lookup of various properties
  validate :lookups_succeeded

  # look for an "magic" event properties that run state changes,
  # if successful, these will be run after save
  validate :validate_aasm_event, :if => Proc.new {|p| p.aasm_event.present?}

  delegate :stages, :to => :plan_template
  delegate :template_type, :to => :plan_template
  delegate :template_type_label, :to => :plan_template

  before_validation :find_plan_template, :find_release
  after_create :build_requests_for_stages, :push_msg, :build_plan_stage_instances
  after_save :set_stage_dates, :set_release_for_requests
  after_update :run_aasm_event, :if => Proc.new {|l| l.aasm_event.present?}
  after_update :push_msg, :unless => Proc.new {|l| l.aasm_state_changed?}

  scope :starting_in, ->(from, to) {
    if from.present? and to.blank?
      where('plan_env_app_dated.planned_complete >= ?', from)
    elsif from.blank? and to.present?
      where('plan_env_app_dated.planned_start <= ?', to)
    elsif from.present? and to.present?
      where "( plan_env_app_dates.planned_start BETWEEN ? AND ? ) OR " +
            "( plan_env_app_dates.planned_complete BETWEEN ? AND ? ) OR " +
            "( plan_env_app_dates.planned_start <= ?  AND  plan_env_app_dates.planned_complete >= ? ) OR " +
            "(plan_env_app_dates.planned_complete is NULL AND plan_env_app_dates.planned_start <= ?) OR " +
            "(plan_env_app_dates.planned_complete is NULL AND plan_env_app_dates.planned_start is NULL)",
            from, to,
            from, to,
            to, from,
            to
    elsif from.blank? and to.blank?
      scoped
    end
  }

  scope :filter, ->(conditions_for_plans, exclude_archived_if_without_filter) {
    where(conditions_for_plans).where(exclude_archived_if_without_filter)
  }

  scope :filter_with_relations, ->(finder_opts_for_calendar) {
    if finder_opts_for_calendar.blank?
      scoped
    else
      where plan_env_app_dates: finder_opts_for_calendar
    end
  }

  ##################### REPORTING FUNCTIONS ################################

  # named scope to join applications back through app_requests,
  # requests, life_cycle_members, and finally plans.
  def applications
    return App.for_plan(self.id)
  end

  def application_name_labels
    self.applications.map(&:name).sort.to_sentence
  end

  def self.status_filters_for_select
    aasm.states.map{|state| [state.name.to_s.humanize, state.name.to_s] unless state.name.eql?(:deleted)}.compact
  end

  def has_app(app_id)
    return self.applications.map(&:id).include?(app_id)
  end

  def application_environments_for_app(app_id)
    self.application_environments.select{|ae| ae.app_id == app_id}
  end

  def application_environments
    return ApplicationEnvironment.for_plan(self.id)
  end

  def routed_app_ids
    plan_routes.map(&:route_app_id).compact.sort
  end

  def routed_apps
    plan_routes.map(&:route_app)
  end

  def environments
    return Environment.for_plan(self.id)
  end

  def environments_for_app(app_id)
    environment_ids = application_environments_for_app(app_id).map(&:environment_id).uniq.sort
    return environments.select { |e| environment_ids.include?(e.id) }
  end

  def release_label
    my_label = []
    my_label << "Rel: #{self.release.try(:name)}" if self.release
    my_label << "Mgr: #{self.release_manager.try(:short_name)}" if self.release_manager
    my_label << "Date: #{self.try(:release_date)}" if self.release_date
    return my_label.join(" / ")
  end

  # this is an expandable method to test if the plan has constraints
  # applied to it, initially in the form of routes, but later environment
  # windows and version sets
  def is_constrained?
    plan_routes.any?
  end


  protected

  # when a plan is first created, we should instruct the stages to build the requests
  def build_requests_for_stages
    transaction do
      begin
        stages.with_request_template.each do |stage|
          stage.create_plan_members_for_plan(self)
        end
      rescue => ex
        message = "could not create requests for stages. #{ex.backtrace}"
        Rails.logger.error message
        raise ActiveRecord::Rollback, message
      end
    end
  end

  # when a plan is first created, we should build the plan_stage instances as well
  def build_plan_stage_instances
    stages.each do |stage|
      self.plan_stage_instances.find_or_create_by_plan_stage_id(stage.id)
    end
  end

  # automatic launching of requests after save
  def start_requests_if_autostart
    # Code to planned and started Request.
    first_stage = self.stages.first
    if self.plan_template.is_automatic?
      self.plan_it!
      self.start!
      self.stages.each do |stage|
        members = self.members.for_stage(stage.id) if stage.auto_start?
        members.try(:each) do |member|
          if !member.nil? && member.stage.auto_start?
            request = member.request
            request.plan_it! if request.aasm_state.eql?('created')
            request.start_request! if request.aasm_state.eql?('planned')
          end
        end
      end
    end
  end

  # update loads a simple array of ids and dates into the attribute
  # stage_date instead of bothering with a complex multi-model form
  def set_stage_dates
    return if self.stage_date.blank?
    self.stage_dates.destroy_all
    self.stage_date.each_pair { |plan_stage_id, dates|
      self.stage_dates << PlanStageDate.create(:plan_stage_id => plan_stage_id,
      :start_date => dates["start_date"],
      :end_date => dates["end_date"])
    }
  end

  # Update Requests 'release_id' from this plan whenever it has been updated
  # or created with data, used to be an explicit call in the controller
  def set_release_for_requests
      self.members.each do |member|
        request = member.request
        request.update_attribute(:release_id, self.release_id) unless request.nil?
      end unless self.release_id.nil?
  end

  # convenience finder (mostly for REST clients) that allows you to pass a plan_template_name
  # and have us look up the correct plan template for you
  def find_plan_template
    unless self.plan_template_name.blank?
      self.plan_template = PlanTemplate.find_by_name(self.plan_template_name)
      self.plan_template_name_lookup_failed = self.plan_template.nil?
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  # convenience finder (mostly for REST clients) that allows you to pass a plan_template_name
  # and have us look up the correct plan template for you
  def find_release
    unless self.release_name.blank?
      self.release = Release.find_by_name(self.release_name)
      self.release_name_lookup_failed = self.release.nil?
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  def lookups_succeeded
    self.errors.add(:plan_template_name, "was not found in plan templates table.") if self.plan_template_name_lookup_failed
    self.errors.add(:release_name, "was not found in releases table.") if self.release_name_lookup_failed
  end

  def validate_aasm_event
    self.executable_event ||= AasmEvent::PlanExecuteEvent.new(self)
    self.executable_event.validate_aasm_event
  end

  # if an aasm_event was passed through parameters on an update or create with no errors, then run it
  def run_aasm_event
    # make sure the is a command waiting to run and there are no errors on it.
    self.executable_event.run_aasm_event if self.errors[:aasm_event].blank?
  end

  def project_server_exists
    if !project_server_id.nil? && ProjectServer.where(id: project_server_id).blank?
      errors.add(:project_server_id, :existence, message: [:"#{self.class.i18n_scope}.errors.messages.existence", "does not exist"])
    end  
  end  

  def release_manager_exists
    if !release_manager_id.nil? && User.where(id: release_manager_id).blank?
      errors.add(:release_manager_id, :existence, message: [:"#{self.class.i18n_scope}.errors.messages.existence", "does not exist"])
    end  
  end  
end
