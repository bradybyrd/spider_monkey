################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

require 'sortable_model'

class Request < ActiveRecord::Base
  include TorqueBox::Messaging::Backgroundable

  # all states:
  # created, planned, started, problem, hold, cancelled, complete, deleted
  ALLOWED_TO_REMOVE_SERVER = %W(created planned cancelled)

  attr_accessible :owner, :requestor, :name, :requestor_id, :owner_id,
    :app_ids, :environment_id, :business_process_id, :description, :release_id,
    :activity_id, :wiki_url, :estimate, :rescheduled, :scheduled_at_date,
    :scheduled_at_hour, :scheduled_at_minute, :scheduled_at_meridian,
    :target_completion_at_date, :target_completion_at_hour,
    :target_completion_at_minute, :target_completion_at_meridian, :notes,
    :scheduled_at, :started_at, :target_completion_at, :completed_at,
    :should_time_stitch, :package_content_ids, :app_id, :promotion,
    :selected_components, :promotion_source_env, :notify_on_request_start,
    :notify_on_request_hold, :notify_on_request_complete,
    :notify_on_step_start, :notify_on_step_block, :notify_on_step_complete,
    :additional_email_addresses, :uploads, :auto_start,
    :plan_member_attributes, :uploads_attributes,:environment,
    :deployment_coordinator, :activity, :aasm_state, :cancelled_at,
    :category_id, :created_at, :created_from_template, :deleted_at,
    :deployment_coordinator_id, :plan_member_id, :planned_at,
    :request_template_id, :server_association_id, :server_association_type,
    :updated_at, :notify_on_request_cancel, :notify_on_step_problem,
    :notify_on_step_ready, :notes_attributes, :aasm_event,
    :deployment_window_event_id, :notify_on_request_planned,
    :notify_on_request_problem, :notify_on_request_resolved,
    :notify_on_request_step_owners, :notify_on_step_step_owners,
    :notify_on_step_requestor_owner, :notify_on_request_participiant,
    :notify_on_step_participiant, :notify_group_only,
    :automatically_start_errors, :notify_on_dw_fail, :deployment_window_event,
    :parent_request_id

  cattr_writer :base_number
  attr_accessor :log_comments, :selected_components, :promotion_source_env, :state_changer,
                :should_time_stitch, :add_blank_steps_with_components,
                :copied_from_template, :import_note, :aasm_event, :aasm_event_note, :view_object,
                :skip_check_if_able_to_create_request_validation, :check_permissions, :executable_event,
                :environment_ids

  # TODO: RJ: Rails 3: Log activities plugin is not compatible with rails 3
  #log_activities

  extend AssociationFreezer::ModelAdditions
  extend RequestCSV
  extend RequestParticipation

  include ExposedTime
  include StepContainer
  include CalendarInstanceMethods
  include ApplicationHelper
  include QueryHelper
  include Messaging

  acts_as_messagable
  acts_as_stomplet_eventable

  # moved to the top to make it clear at a glance the full contents of the class
  concerned_with :named_scopes
  concerned_with :summary
  concerned_with :import_request, :import_app_request
  # adding a new separate state machine file so we can focus in on that behavior and call
  # backs without struggling through the larger class
  concerned_with :request_state_machine
  concerned_with :clone_request

  DefaultBaseNumbersForSelect = [["1000", 1000], ["10000", 10000]]
  EventsForCategories = %w(problem resolve cancel)
  RequestRunnerPidFile = "#{Rails.root}/tmp/run_requests.pid"

  TimeLap = {
    'last week'    => 1.week.ago,
    'last 2 weeks' => 2.weeks.ago,
    'last month'   => 1.month.ago,
    'last 3 months'=> 3.months.ago,
    'last year'    => 1.year.ago
  }

  cattr_accessor :old_object

  expose_time_for_selector :scheduled_at, :target_completion_at, :completed_at, :started_at
  # before_validation :reformat_dates_to_us_format
  before_validation :stitch_together_scheduled_at, :stitch_together_target_completion_at,
                    :stitch_together_completed_at, :stitch_together_started_at, if: :should_time_stitch

  before_save :ensure_environment
  before_save :delete_associated_tickets
  # before_save :update_step_script_arguments
  after_save :save_application_associations
  after_save :add_entry_to_plan_env_app_dates, if: Proc.new {|request| request.plan_member_id.present?}
  after_save :change_server_selections!, if: Proc.new {|request| request.environment_id_changed?}
  after_save :schedule_auto_start, if: :should_be_scheduled
  after_save :unschedule_auto_start, if: :should_be_unscheduled

  before_save :check_dws
  before_save :ensure_aasm_state_present
  after_create :created!, :increment_counter_in_events, :increment_counter_in_series
  after_create :add_blank_steps, if: Proc.new {|r| r.add_blank_steps_with_components }

  # before destroy, we need to remove plan member
  before_destroy :remove_plan_member, :nullify_child_relation, :destroy_steps
  before_update :save_old_object

  after_update :run_aasm_event, if: Proc.new {|r| r.aasm_event.present?}

  belongs_to :environment
  belongs_to :business_process
  belongs_to :deployment_coordinator, class_name: "User"
  belongs_to :requestor, class_name: "User"
  belongs_to :owner, class_name: "User"
  belongs_to :release
  belongs_to :category
  belongs_to :request_template
  belongs_to :request_template_origin, foreign_key: :origin_request_template_id, class_name: 'RequestTemplate'
  belongs_to :activity
  belongs_to :plan_member
  belongs_to :server_association, polymorphic: true
  belongs_to :parent_request_origin, class_name: 'Request', foreign_key: :parent_request_id
  belongs_to :deployment_window_event, class_name: 'DeploymentWindow::Event'

  has_many :associated_current_property_values, as: :value_holder, class_name: 'PropertyValue', dependent: :destroy, conditions: 'deleted_at IS NULL'
  has_many :associated_deleted_property_values, as: :value_holder, class_name: 'PropertyValue', dependent: :destroy, conditions: 'deleted_at IS NOT NULL'
  has_many :associated_property_values, as: :value_holder, class_name: 'PropertyValue', dependent: :destroy
  has_many :temporary_property_values, dependent: :destroy
  has_many :temporary_current_property_values, class_name: 'TemporaryPropertyValue', dependent: :destroy, conditions: 'deleted_at IS NULL'
  has_many :apps_requests, dependent: :destroy
  has_many :application_environments_by_apps, source: :application_environments, through: :apps
  has_many :apps, through: :apps_requests
  has_many :steps, dependent: :destroy
  has_many :executable_steps, class_name: "Step", conditions: { procedure: false }, order: "position ASC"
  has_many :checked_steps, class_name: "Step", conditions: { should_execute: true }
  has_many :procedures, class_name: "Step", conditions: {procedure: true}, order: "position ASC"
  has_many :messages, order: 'created_at DESC', dependent: :destroy
  has_many :logs, class_name: 'ActivityLog', dependent: :destroy, order: 'created_at DESC, usec_created_at DESC'
  has_many :design_logs, class_name: 'ActivityLog', conditions: { type: "design"}, dependent: :destroy, order: 'created_at DESC, usec_created_at DESC'
  has_many :runtime_logs, class_name: 'ActivityLog', conditions: { type: "runtime"}, dependent: :destroy, order: 'created_at DESC, usec_created_at DESC'
  has_many :email_recipients, dependent: :destroy
  has_many :uploads, as: :owner, dependent: :destroy
  has_many :request_package_contents, dependent: :destroy
  has_many :package_contents, through: :request_package_contents
  has_many :step_holders, dependent: :destroy
  has_many :notes, as: :object, dependent: :destroy
  has_many :app_environments, through: :apps, source: :environments
  has_many :available_components, through: :apps, conditions: ->(*args) { ['application_environments.environment_id = ?', self.environment_id] }
  has_many :scheduled_jobs, as: :resource, dependent: :destroy

  validates_with PermissionsPerEnvironmentValidator

  validates :requestor, presence: true
  validates :deployment_coordinator, presence: true
  # validates_presence_of :environment_id
  # validate :existence_of_an_app
  validate :app_environment_association_validation
  validate :validate_additional_email_address, unless: Proc.new { |r| r.additional_email_addresses.nil_or_empty? }
  validates :name, length: { maximum: 255 }
  validate :validate_aasm_event, if: Proc.new {|r| r.aasm_event.present?}
  # when a request is created, we want to check that it is complaint with constraints on the
  # plan stage instance and reject noncompliant
  validate :request_compliance, if: Proc.new { |r| r.plan_member.present? && r.plan_member.plan_stage_id.present? }
  # a validation for strict plan control for requests (not request templates) whose applications have this checked
  validate :check_for_strict_plan_control, if: Proc.new { |r| !r.template? }
  validate :check_if_able_to_create_request, unless: :skip_check_if_able_to_create_request_validation
  validate :check_deployment_window_event, if: :environment
  validate :scheduled_at_correct, if: :auto_start
  validate :possibility_to_auto_start, if: :auto_start

  # allows form fields from request creation and update to flow directly to plan member without
  # complex callbacks, rejecting blanks and invalid entries
  accepts_nested_attributes_for :plan_member, reject_if: proc { |attributes| attributes['id'].blank? && attributes['plan_id'].blank?  }, allow_destroy: true

  # allow for uploads (a.k.a. assets) to be set through a nested form and updated without special
  # attribute accessors and prevalidation hooks.  This provides passthrough validatin messages to those forms.
  accepts_nested_attributes_for :uploads, reject_if: lambda { |a| a[:attachment].blank? }, allow_destroy: true
  accepts_nested_attributes_for :notes, allow_destroy: true

  delegate :plan, to: :plan_member, allow_nil: true
  delegate :run, to: :plan_member, allow_nil: true
  delegate :name, to: :business_process, prefix: true, allow_nil: true
  delegate :name, to: :release,          prefix: true, allow_nil: true
  delegate :name, to: :app,              prefix: true, allow_nil: true
  delegate :name, to: :environment,      prefix: true, allow_nil: true
  delegate :name, to: :requestor,        prefix: true, allow_nil: true
  delegate :name, to: :owner,            prefix: true, allow_nil: true
  delegate :contact_number, to: :requestor,        prefix: true, allow_nil: true
  delegate :contact_number, to: :owner,            prefix: true, allow_nil: true
  delegate :name_for_index, to: :requestor, prefix: true, allow_nil: true
  delegate :name_for_index, to: :owner,     prefix: true, allow_nil: true
  delegate :name, to: :deployment_window_event, prefix: true, allow_nil: true

  scope :none, where(id: nil)

  acts_as_audited except: [:frozen_app,
                              :frozen_requestor,
                              :frozen_environment,
                              :frozen_business_process,
                              :frozen_deployment_coordinator,
                              :frozen_release]


  sortable_model
  enable_association_freezer

  SortScope = [:aasm_state, :activity_id, :package_content_id, :release_id, :app_id, :team_id,
               :environment_id, :requestor_id, :owner_id]

  can_sort_by :owner, lambda {|asc|
    order = asc ? "ASC" : "DESC"
    if MsSQLAdapter
      { order: "(users.last_name +' '+ users.first_name) #{order}",
      include: :owner }
    else
      { order: PostgreSQLAdapter ? "TEXTCAT ( TEXTCAT (users.last_name,' '), users.first_name) #{order}":  "concat ( concat (users.last_name,' '), users.first_name) #{order}",
      include: :owner }
    end
  }

  can_sort_by :requestor, lambda {|asc|
    order = asc ? "ASC" : "DESC"
    if MsSQLAdapter
      { order: "(users.last_name +' '+ users.first_name) #{order}",
    include: :requestor }
    else
      { order: PostgreSQLAdapter ? "TEXTCAT ( TEXTCAT (users.last_name,' '), users.first_name) #{order}":  "concat ( concat (users.last_name,' '), users.first_name) #{order}",
    include: :requestor }
    end
  }

  can_sort_by :duration, lambda {|asc|
    order = asc ? "ASC" : "DESC"
    time_diff = if OracleAdapter
      "(coalesce(completed_at,started_at,sysdate) - coalesce(started_at,completed_at,sysdate))"
    else
      "(coalesce(completed_at, started_at, current_timestamp) - coalesce(started_at, completed_at, current_timestamp))"
    end
    { order: "#{time_diff} #{order}" }
  }

  can_sort_by :executable_step_count, lambda { |asc|
    order = asc ? "ASC" : "DESC"
    {
      select: "#{Request.exclude_clob_columns}",
      joins: :steps,
      conditions: ["steps.#{PROCEDURE_COLUMN} = ? OR steps.#{PROCEDURE_COLUMN} IS NULL", false],
      order: "count(steps.id) #{order}",
      group: 'requests.id'
    }
  }


  can_sort_by :app, lambda { |asc|
    order = asc ? "ASC" : "DESC"
    {
      include: {apps_requests: :app},
      order: "apps.name #{order}"
    }
  }

  can_sort_by :team , lambda{ |asc|
    order = asc ? 'ASC' : 'DESC'
    {
      order: "teams.name #{order}",
      include: {apps_requests: {app: { development_teams: :team }}}
    }
  }

  can_sort_by :package_contents , lambda{ |asc|
    order = asc ? 'ASC' : 'DESC'
    {
      order: "package_contents.name #{order}",
      include: :package_contents
    }
  }

  can_sort_by :project, lambda{|asc|
    order = asc ? 'ASC' : 'DESC'
    {
      order: "activities.name #{order}",
      include: :activity
    }

  }

  can_sort_by release: :name
  can_sort_by business_process: :name
  can_sort_by environment: :name
  can_sort_by :scheduled_at
  can_sort_by :target_completion_at
  can_sort_by :aasm_state
  can_sort_by :name
  can_sort_by :id
  can_sort_by :created_at
  can_sort_by :started_at

  @scheduler_thread = nil
  @mutex = Mutex.new

  # To get top_level steps with eagerly loaded required associated records.
  def get_all_top_level_steps
    sub_steps_associations_to_include = [:package_template, :servers, :server_aspects, :server_groups,
                                         :owner, :request, {automation_script: :arguments}, {bladelogic_script: :arguments},
                                         :parent, :component, :package, :floating_procedure]
    steps_associations_to_include = sub_steps_associations_to_include + [:execution_condition]
    steps.top_level.includes(steps_associations_to_include, steps: sub_steps_associations_to_include)
  end

  def last_step_of_req
     steps.where("parent_id IS NULL").order("position DESC").limit(1).first
  end

  def ordered_steps(executable = nil)
    (executable.nil? ? self.steps : self.executable_steps.includes(:steps, :parent, :notes)).sort{ |a,b| a.number_real <=> b.number_real }
  end

  def self.request_app_id(search_query)
    App.where('apps.name LIKE ?', "%#{search_query}%").pluck(:id)
  end

  def self.request_environment_id(search_query)
    Environment.where('environments.name LIKE ?', "%#{search_query}%").pluck(:id)
  end

  def self.request_business_process(search_query)
    BusinessProcess.where('business_processes.name LIKE ?', "%#{search_query}%").pluck(:id)
  end

  def self.request_owner(search_query)
    User.where('users.first_name LIKE ? OR last_name LIKE ?', "%#{search_query}%", "%#{search_query}%").pluck(:id)
  end

  def self.in_month(date_in_month=Time.now)
    start_date = date_in_month.beginning_of_month
    end_date = date_in_month.end_of_month
    between_dates(start_date, end_date)
  end

  def self.first_request_time
    if Request.first.blank?
      Date.generate_from(Date.today)
    else
      Date.generate_from(Request.first.created_at.to_date)
    end.to_time.beginning_of_day.in_time_zone
  end

  # Rajesh: Check with Brady/Charles/Piyush
  # If this functionality is used?
  # Putting in a temporary fix
  # Either create a proper fix using threads after consulting with Manish/Brady
  # or get rid of this functionality
  def self.start_request_launcher!
    @mutex.synchronize {
        if @scheduler_thread == nil
            @scheduler_thread = Thread.new {
              loop do
                sleep Time.now.seconds_until_next_quarter_hour
                Request.automatic_request_execution
              end
            }
        end
    }
  end

  def self.stop_request_launcher!
    @mutex.synchronize {
      if @scheduler_thread != nil
        @scheduler_thread.kill
        @scheduler_thread = nil
      end
    }
  end

  def self.automatic_request_execution
    create_recurring_requests!
    start_automatic_requests!
  end

  def self.start_automatic_requests!
    automatic_ready_to_start.each do |request|
      request.start_request!
    end
  end

  def self.create_recurring_requests!
    if Date.today.weekday?
      RequestTemplate.recurring_at(Time.current).each do |template|
        recurring_request = template.create_request_for(template.request.user)
        recurring_request.auto_start = true
        recurring_request.scheduled_at = template.recur_time
        recurring_request.plan_it!
      end
    end
  end

  def self.last_successful_deploy_for_application_and_environment(app_id, env_id)
    find(:first, joins: ["INNER JOIN apps_requests ON apps_requests.request_id = requests.id "],
         conditions: ["apps_requests.app_id = ? AND environment_id = ? AND completed_at IS NOT NULL", app_id, env_id], order: 'completed_at DESC')
  end

  def self.find_by_number(num, options = {})
    find(id_by_number(num), options)
  end

  def self.id_by_number(num)
    num.to_i - GlobalSettings[:base_request_number]
  end

  def self.status_filters_for_select
    ([["Active", "active"]] + aasm.states.map { |state| [state.name.to_s.humanize, state.name.to_s] })
  end

  def self.status_filters_options # Card: 2976338
    ['cancelled', 'complete', 'deleted'].map { |state| [state.humanize, state] }.sort
  end

  def self.create_consolidated_request(request_ids, user)
    return unless request_ids
    requests = find_in_order_of request_ids
    return if requests.first.apps.first.strict_plan_control == true

    new_request = Request.create! environment: requests.first.environment,
                                  deployment_coordinator: user, requestor: user,
                                  name: requests.map { |r| r.number }.join(', '),
                                  activity: requests.first.activity,
                                  app_ids: requests.first.apps.map(&:id)

    requests.map { |r| r.executable_steps }.flatten.group_by { |s| s.phase }.each do |phase, steps|
      new_proc_step = new_request.steps.build name: phase.try(:name) || '[No Phase]'
      new_proc_step.add_assorted_steps steps
      new_proc_step.save!
    end
    new_request
  end

  def self.get_problem_count_of(requests)
    activity_logs = ActivityLog.get_problems_of(requests.map(&:id))
    [ activity_logs.select {|a| a.activity == 'Problem' && !a.activity.include?("Step")}.map(&:request_id),
      activity_logs.select {|a| a.activity.include?('Blocked')}.map(&:request_id),
      activity_logs.select {|a| a.activity == 'Hold'}.map(&:request_id)
    ]
  end

  def self.get_problematic_requests(requests)
    activity_logs = ActivityLog.get_problems_of(requests.map(&:id))
    activity_logs.select {|a| a.activity == 'Problem' && !a.activity.include?("Step")}.map(&:request_id)
  end

  def self.by_start_or_end_date(start_date, end_date)
    if start_date && end_date
      completed_in_duration(start_date, end_date).complete.started_at_not_null.completed_at_not_null
    else
      from_time_until_now(Request::TimeLap[start_date]).complete
    end
  end

  def self.cancelled_between(start_date, end_date)
    if start_date && end_date
      cancelled_in_duration(start_date, end_date)
    else
      cancelled_from_time_until_now(Request::TimeLap[start_date])
    end.aasm_state_equals("cancelled")
  end

  def self.exclude_clob_columns
    column_names.reject{|c| c.include?("frozen") || c.include?("description") || c.include?("notes") || c.include?("wiki")}.map{|c| "#{table_name}.#{c}"}.join(",")
  end

  # This callback method will be called on successfull start of a Request
  def update_steps_status
    update_started_at =  ['problem','hold'].include?(self.aasm_state)
    self.update_attribute(:started_at, Time.now) unless update_started_at#unless started_at?
    if steps.top_level.includes(:parent).all? { |step| step.complete_or_not_executable? }
      finish!
    else
      prepare_steps_for_execution
    end
  end

  def view_object
    @view_object ||= RequestView.new
  end

  #TODO: These four user methods are for backwards compatibility.  They will be removed.
  def user
    deployment_coordinator
  end

  def user=(new_user)
    self.deployment_coordinator = new_user
  end

  def user_id
    deployment_coordinator_id
  end

  def user_id=(new_user_id)
    self.deployment_coordinator_id = new_user_id
  end

  def uploads=(new_uploads)
    new_uploads.each do |uploaded_data|
      uploads.build(attachment: uploaded_data) unless uploaded_data.blank?
    end
  end

  def unassigned?
    environment_id.blank? || application_environments.empty?
  end

  def application_environments
    @application_environments ||= {}
    @application_environments[app_envs_memo_key] ||= load_application_environments
  end

  def application_environments=(app_envs)
    @application_environments ||= {}
    @application_environments[app_envs_memo_key] = app_envs
  end

  def load_application_environments
    if missing_environments_by_apps?
      ApplicationEnvironment.where(environment_id: environment_id, app_id: app_ids)
    else
      application_environments_by_apps.where(environment_id: self.environment_id)
    end
  end

  def missing_environments_by_apps?
    application_environments_by_apps.empty? && environment_id && app_ids ||
      !app_ids_match?
  end

  def app_ids_match?
    (application_environments_by_apps.map(&:app_id) | app_ids) == app_ids
  end

  def destroy_with_paranoia
    if cancelled? || complete?
      soft_delete!
    else
      destroy_without_paranoia
    end
  end
  alias_method_chain :destroy, :paranoia

  def destroy_steps
    self.steps.where('parent_id is null').each do |step|
      step.destroy
    end
  end

  def order_time
    started_at || scheduled_at || created_at
  end

  def humanized_calendar_time_source
    { scheduled_at:         "Start",
      started_at:           "Started",
      target_completion_at: "Due By" }[calendar_time_source]
  end

  def calendar_time_source
    [:started_at, :scheduled_at, :target_completion_at].detect do |attr|
      send(attr).present?
    end
  end

  def additional_email_addresses
    return [] unless self[:additional_email_addresses]
    self[:additional_email_addresses].split(/[,;\s]+/)
  end

  def number
    id.to_i + GlobalSettings[:base_request_number]
  end

  def deletable_by?(requesting_user)
    !template? && requesting_user.can?(:delete, self)
  end

  def due_before_scheduled?
    return false if scheduled_at.blank? or target_completion_at.blank?
    target_completion_at < scheduled_at
  end

  def template?
    !request_template.nil?
  end

  def total_duration
    (completed_at.blank? || started_at.blank?) ? 0 : (completed_at - started_at).to_i / 60
  end

  def steps_to_consider(step_type)
    steps_in_calculation = if step_type.blank?
      steps
    elsif step_type == "auto"
      steps.where(manual: false)
    elsif step_type == "manual"
      steps.where(manual: true)
    elsif step_type.is_a?(Hash)
      if step_type.has_key?('group_id')
        steps.where(owner_type: 'Group').where(owner_id: step_type['group_id'])
      else step_type.has_key?('work_task_id')
        steps.where(work_task_id: step_type['work_task_id'])
      end
    end.should_execute
  end

  def total_duration_steps(step_type=nil) # TODO - Check with PP - Is this Redundant?
    steps_in_calculation = steps_to_consider(step_type)
    ss_estimate = steps_in_calculation.serial_steps.select{|s| s.estimate}.map(&:estimate)
    long_running_parallel_step_est = steps_in_calculation.parallel_steps.select {
      |s| s.estimate}.map(&:estimate).sort.last
    ss_estimate << long_running_parallel_step_est unless long_running_parallel_step_est.nil?
    ss_estimate.flatten.compact.sum
  end

  def already_started?
    [:started, :problem, :complete].include?(aasm.current_state)
  end

  def in_process?
    [:started, :problem, :hold].include?(aasm.current_state)
  end

  def editable_by?(user)
    return false if already_started?
    return false if cancelled?
    is_available_for?(user)
  end

  def setup_recurrance(schedule)
    recur_time = Time.parse("#{schedule[:hour]}:#{schedule[:minute]} #{schedule[:meridian]}")
    RequestTemplate.initialize_from_request(self, name: "Recurring Request #{number}", recur_time: recur_time).save
  end

  def start_request!
    start!
  end


  # FIXME: The request state machine transition logic has been spread out between the requests controller,
  # the request model call backs, and some new special methods to support remote starting.  This should all
  # be factored (especially the controller bits) to rely on the :success parameter of each transition state
  # so we can use the original state machine verbs (start!, etc) and have the same behavior from all sides.
  def remote_start
    cur_state = aasm_state
    available_events = aasm_events_for_current_state
    cur_groups = participant_groups
    msg = "Request: #{id.to_s} - #{name}:\n "
    msg += "\tApplication: #{self.app_name.join(", ")}\n\tEnvironment: #{environment_label}\n"
    msg += "\tSteps: #{steps.should_execute.size}\n\t\tAutomated: #{automatic_steps.size}\n\n\t\tManual: #{manual_steps.size}\n"
    if available_events.include?(:plan) || available_events.include?(:start)
      plan_it! if available_events.include?(:plan)
      #result = start_request!
      th = Thread.new {
        puts "starting Req: #{id.to_s}"
        result = start_request!
      }
      msg += " Action: Started at #{Time.now.to_s}"
    else
      msg += " Failed: Cannot start - current state = #{cur_state}"
    end
    msg
  end


  def freeze_request!
    self.apps_requests.each do |app|
      app.freeze_app
      app.save!
    end
    freeze_environment
    freeze_business_process
    freeze_requestor
    freeze_deployment_coordinator
    freeze_release

    # Log to recent_activities on request completion.
    request_data = name.blank? ? number : name
    req_link = request_link(number)
    # TODO: RJ: Rails 3: Log Activity plugin incompatible with rails 3
    # TODO: CF: Had to comment out the save too which I think was supposed to run only with
    # the context of the two lines RF commented out.  Hopefully we can move this stuff
    # to the state machine and clean it up!
    #User.current_user.nil? ? User.first : User.current_user).log_activity(context: "#{req_link} has been #{aasm_state}") do
      save(validate: false)
    #end
    update_attribute(:cancelled_at, Time.now)
  end

  def unfreeze_request!
    self.apps_requests.each do |app|
      app.unfreeze_app
      app.save!
    end
    unfreeze_environment
    unfreeze_business_process
    unfreeze_requestor
    unfreeze_deployment_coordinator
    unfreeze_release

    steps.each{ |st| st.unfreeze_step! }
    save!
  end

  def steps_for_procedure_creation
    @steps_for_procedure_creation ||= executable_steps.where(should_execute: true)
  end

  def steps_with_invalid_components
    available_component_ids = available_components.pluck('components.id')
    executable_steps.
      includes(:request, installed_components: [:servers, :server_group, :server_aspects, :server_aspect_groups]).
      where('steps.aasm_state != ?', 'complete').
      where('steps.component_id IS NOT NULL').
      where('steps.component_id NOT IN (?)', available_component_ids)
  end

  def participant_names
    Request.participated_by_user_and_group(self.id).map(&:name)
  end

  def request_view_step_headers(step_ids=nil)
#   ActiveRecord::Base.connection.execute(SQL_QUERY).all_hashes is replaced by find_by_sql(SQL_QUERY)
#   Because connection.execute(SQL_QUERY).methods.include?('all_hashes') == false
    step_headers = Request.find_by_sql(Request.request_view_step_headers_sql(self, step_ids))
#    merge servers for step with rest of step_header
    step_ids ||= step_headers.map{|h| h['id'] }
    servers_by_id = server_names_for_steps(step_ids)
    servers_by_id.stringify_keys! if servers_by_id.respond_to?(:stringify_keys)
    step_headers.inject({}) do |total,sh|
      #sh.raw_write_attribute 'server', servers_by_id[sh['id'].to_s]
      sh['server'] = servers_by_id[sh['id'].to_s]
      total[sh['id'].to_s] = sh
      total
    end
  end

  def server_names_for_steps(step_ids)
    return [] if step_ids.blank?
    servers_by_id = step_ids.inject({}){|total,step_id| total[step_id] = []; total }
    return [] if servers_by_id.blank?
    servers_by_id_results = Request.get_server_names_for_steps(step_ids)
    servers_by_id_results.inject(servers_by_id) do |total,row|
      total.stringify_keys!
      id = row['step_id']
      server = row['name']
      total[id] << server if total[id]
      total
    end
    servers_by_id
  end

  def headers_for_request
    # BJB Returns a hash of values for automation scripts
    unless plan_member.nil?
      lifec = plan_member.plan.try(:name)
      plan_stage = plan_member.stage.try(:name)
      plan = lifec.nil? ? "" : lifec
      plan_stage_id = plan_member.plan_stage_id
      lc_member_id = plan_member_id
    else
      plan = ""
      plan_stage = ""
      plan_stage_id = ""
      lc_member_id = -1
    end

    res = {
      "request_name" => name.present? ? name.gsub("'","''") : "",
      "request_status" => aasm.current_state.to_s,
      "request_plan_member_id" => lc_member_id,
      "request_plan" => "#{plan}",
      "request_plan_stage" => "#{plan_stage}",
      "request_project" => activity.try(:name) || "",
      "request_started_at" => "#{started_at}",
      "request_planned_at" => "#{planned_at}",
      "request_owner" => owner_name_for_index,
      "request_wiki_url" => wiki_url,
      "request_requestor" => requestor_name_for_index,
      "request_application" => Array(app_name).try(:join, ",") || "",
      #"request_description" => description.blank? ? "" : description.gsub("'","''"),
      "request_number" => self.number,
      "SS_request_number" => self.number,
      "request_run_id" => self.run.blank? ? "" : self.run.id,
      "request_run_name" => self.run.blank? ? "" : self.run.name,
      "request_login" => User.current_user.nil? ? last_user.login : User.current_user.login,
      "request_plan_id" => self.plan.nil? ? "" : self.plan.id,
      "request_environment" => self.environment.try(:name) || "",
      "request_environment_type" => self.environment.try(:environment_type).try(:name) || "",
      "request_notes" => self.recently_added_note || "",
      "request_scheduled_at" => "#{self.scheduled_at}",
      "request_process" => self.business_process.try(:name) || "",
      "request_release" => self.release.try(:name) || "" ,
      "request_cancellation_category" => self.category.try(:name) || "",
      "parent_request_id" => parent_request_id || ""
    }
  end

  # very long notes with formatting were causing issues in the script parsing
  # FIXME: request_note is removed in the automation library lib/automation_common.rb,
  # but should not be added in the first place
  # on line 725 if it is not needed
  def recently_added_note
    content = self.notes.order("created_at desc").first.try(:content) || ""
    content = content[0..50] + "..." if content.length > 50
    return content
  end

  def count_components_related
    res = connection.select_rows("select count(distinct s.component_id) from steps s where s.request_id = #{id}")
    res[0][0]
  end

  def count_users_assigned_steps
    res = connection.select_rows("select count(distinct s.owner_id) from steps s where s.request_id = #{id}")
    res[0][0]
  end


  def email_recipients_for(type)
    scope = (type == :all) ? 'all' : type.to_s.downcase.pluralize
    email_recipients.send(scope).map { |recipient| recipient.recipient }
  end

  def email_recipient_ids_for(type)
    scope = type.to_s.downcase.pluralize
    email_recipients.send(scope).map { |recipient| recipient.recipient_id }
  end

  def mailing_list
    recipients = []
    recipients << self.owner.email if self.owner
    recipients << self.requestor.email if self.requestor
    recipients << step_owner_emails(executable_steps) if self.notify_on_request_step_owners
    if notify_on_request_participiant
      recipients << self.additional_email_addresses
      recipients << self.emails_group(self.notify_group_only)
      recipients << self.email_recipients_for(:user).map(&:email)
    end
    recipients.flatten.uniq.delete_if{|e| e.blank? }
  end

  def step_owner_emails(steps = [])
    @step_owners_mail_list ||= RequestStepsEmailList.new.get(steps)
  end

  def emails_group(group_only)
    groups = self.email_recipients_for(:group)
    emails = []
    if group_only
      groups.map do |group|
        emails << (group.email.blank? ? group.resources.map{|user| user.email} : group.email) # in case if group mail is empty we get all users from group
      end
    else
      groups.map { |group| emails << group.email; group.resources.map{|user|emails << user.email} }
    end
    emails
  end

  def has_no_available_package_templates?
    return @has_package_templates unless @has_package_templates.nil?
    @has_package_templates = available_package_templates.blank?
  end

  def available_package_templates
    #if apps.present?
    #  accessible_apps = []
    #  user_accessible_apps = User.current_user.accessible_apps_for_requests
    #  apps.each do |app|
    #    accessible_apps << app if user_accessible_apps.map(&:id).include?(app.id)
    #  end
    #  accessible_apps.flatten.map(&:package_templates).flatten!
    #else
    #  apps.map(&:package_templates).flatten!
    #end
    #User.current_user.accessible_apps_for_requests.map(&:package_templates).flatten!
    User.current_user.accessible_apps_for_requests_with_package_templates.map(&:package_templates).flatten!
  end

  def add_log_comments(type, comments)
    return if comments.blank?

    note = "[#{type.to_s.upcase}"
    note << " -- #{category.name}" if category
    note << "] #{comments}"

    self.log_comments = note
  end

  def set_email_recipients(options)
    sync_email_recipients(:user, options[:user_ids]) if options[:user_ids]
    sync_email_recipients(:group, options[:group_ids]) if options[:group_ids]
  end

  def to_param
    number.to_s
  end

  def is_associated_with_user?(user)
    Request.is_request_associated_with_user?(self, user)
  end

  def current_step
    if complete?
      executable_steps.to_a.reverse.find { |s| s.complete? }
    else
      executable_steps.to_a.find { |s| !s.locked? && !s.complete? }
    end
  end

  def current_phase_name(use_helpful_text_for_no_valid_phase=true)
    na_value = use_helpful_text_for_no_valid_phase ? 'N/A' : ''
    return na_value unless current_step

    none_value = use_helpful_text_for_no_valid_phase ? 'None' : ''
    return none_value unless current_step.phase

    current_step.full_phase_name
  end

  def package_content_tags
    package_contents.map(&:abbreviation).join(', ')
  end

  def used_components
    return [] if selected_components.blank?
    ApplicationComponent.all(conditions: {id: selected_components.split(',')}).map(&:component_id)
  end

  def turn_off_steps # Turn OFF steps whose components were not selected from Source Env
    # Do not apply this rule when Request is created from Template. Let it work during Promotions
    # `copied_from_template` used in RequestTemplate#create_request_for
    return if copied_from_template && selected_components.nil?
    turn_on_steps_with_no_components! and return if selected_components.blank?
    usable_components = used_components
    application_environment = []
    apps = App.find(self.apps_requests.map(&:app_id))
    apps.each do |app|
      application_environment << app.application_environments.find_by_environment_id(promotion_source_env)
    end
    application_environment.compact!
    if application_environment
      installed_components = []
      apps.each do |app|
        installed_components << app.installed_components.find_all_by_application_environment_id(application_environment.map(&:id))
      end
      installed_components.flatten!
      cv_hash = {} # cv_hash => component_version_hash
      installed_components.each { |ic| cv_hash[ic.application_component.component_id] = ic.version }
      steps.each { |s|
        if usable_components.include?(s.component_id) && cv_hash.keys.include?(s.component_id)
          s.set_source_env_version(cv_hash[s.component_id])
        else
          s.turn_off! unless s.component_id.nil? # Do not turn off steps with no components when created from promotion
        end
      }
    end
  end

  def turn_on_steps_with_no_components!
    steps.each {|s| s.turn_off! unless s.component_id.nil? }
  end

  # commit version checkbox should be marked automatiically for the last step for any component that has a version
  def set_commit_version_of_steps
    steps.select{|s| !s.component_version.blank?}.group_by(&:component_id).each_pair{ |component_id, steps|
      steps.last.update_attribute(:own_version, true) if steps.last
    }
  end

  def has_default_env?
    environment_id.blank? ? false : environment_id == Environment.find_by_name("[default]")
  end

  def has_default_app?
    app_id.blank? ? false : app_id == App.find_by_name("[default]")
  end

  def created?
    aasm_state == 'created'
  end

  def has_checked_steps?
    checked_steps.size > 0
  end

  def associated_servers
    server_association.path_string rescue ''
  end

  def lifecyle_name
    plan_member.plan.name rescue ''
  end

  def project_name
    plan_member.activities.map { |a| a.name }.to_sentence rescue ''
  end

  def release_name
    release.try(:name)
  end

  # FIXME: CF: This is also delegated on line 156
  def app_name
    apps.map(&:name).compact
  end

  def app_names_with_version
    apps.collect{|app| "#{app.name} " + (app.app_version.present? ? "#{app.app_version}" : "")}
  end

  def app_version
    apps.collect{|a| a.app_version.present? ? a.app_version : "" }
  end

  def environment_name
    environment.try(:name)
  end

  def get_plan_member_status
    unless plan_member.nil?
      plan = plan_member.plan
      members = plan.members
      if plan.plan_template.is_automatic?
        members.each do |member|
          if !member.nil?
            request = member.request if member
            request.update_request_status_from_plan unless request.nil?
          end
        end
      else
        update_request_status_from_plan
      end
    end
  end

  def update_request_status_from_plan
    if ['created', 'cancelled'].include?(aasm_state)
      plan_it!
      start_request! if aasm_state.eql?('planned')
    elsif ['planned', 'hold'].include?(aasm_state)
      start_request!
    elsif ['problem'].include?(aasm_state)
      resolve!
    end
  end

  def last_activity_by
    logs.first.try(:user_id) || User.first.id
  end

  def last_activity_at
    logs.first.try(:created_at) || 1
  end

  def is_accessible_to?(current_user)
    current_user.admin? || available_users.count > 0
  end

  def available_user_ids
    available_users.map(&:id)
  end

  def available_groups(user_ids = available_user_ids)
    Group.joins(:users).where(users: {id: user_ids}).active.uniq
  end

  def available_users(options={})
    app_ids = options.fetch('app_ids', self.app_ids)
    environment_id = options.fetch('environment_id', self.environment_id)
    ignore_access = !fetch_authorized_users?
    @available_users = User.having_access_to(app_ids, environment_id, ignore_access: ignore_access).
        order('users.last_name, users.first_name')
  end

  def fetch_authorized_users?
    if app_id.blank? && environment_id.blank?
      false
    else
      (has_default_app? || has_default_env?) ? false : true
    end
  end

  # BUG FIX 10/10 CF
  def has_same_env_as?(original_request, cur_env_id = "0")
    unless cur_env_id == "0"
      environment_id == cur_env_id.to_i
    else
      environment_id == original_request.environment_id
    end
  end

  def environment_label
    environment.try(:name)
  end

  def environment_id_in_list
    environment_id.to_s
  end

  def common_environments_of_apps
    envs = apps.active.with_installed_components.map(&:environments)
    unless envs.blank?
      @common_environments = envs.inject(&:&).sort_by(&:name)
    else
      @common_environments = []
    end
  end

  def should_finish?
    if aasm_state == 'started'
      # Called from update - double checks if a request should be marked as complete
      finish! if steps.reload.all? { |step| step.complete_or_not_executable? }
    end
  end

  def is_visible?(user, user_app_ids = [])
    user_app_ids = user.app_ids if user_app_ids.blank?
    user.root? || is_visible_for_non_root?(user, user_app_ids)
  end

  def is_available_for?(user)
    user.can?(:inspect, self) || find_assigned_apps(user).present?
  end

  def is_available_for_current_user?
    is_available_for? User.current_user
  end

  def find_assigned_apps(user)
    AssignedApp.by_user_and_apps(user, app_ids)
  end

  def app_user_ids
    AssignedApp.where( app_id: app_ids ).pluck(:user_id)
  end

  def available_users_with_app
    users = available_users
    user_ids = app_user_ids
    users.keep_if do |user|
      if user_ids.include? user.id
        true
      else
        user.root? || app_ids.blank?
      end
    end
  end

  def position_of_last_step
    #steps.maximum("position", {conditions: ["parent_id IS NULL"]})
    res = connection.select_rows("select max(position) from steps s where s.request_id = #{id} and parent_id is null")
    res[0][0]
  end

  # owner_id is not a required field, so Brady's fix needs one more layer of backup
  def backup_owner
    self.owner_id.blank? ? User.root_users.first : User.find(self.owner_id)
  end

  def last_user
    if logs.any?
      User.find_by_id(logs.last.try(:user_id)) || backup_owner
    else
      backup_owner
    end
  end

  def operation_tickets
    @change_requests = if plan_member.present?
      ChangeRequest.where(plan_id: plan_member.plan_id)
    else
      ChangeRequest.id_not_null
    end
    @change_requests = @change_requests.where(project_server_id: ProjectServer.service_now.map(&:id))
    @change_requests = @change_requests.where(show_in_step: true).ascend_by_cg_no
    @change_requests #.deleted_remotely_equals(false)
  end

  def current_property_values
    associated_current_property_values
  end

  def request_label
    return self.name.blank? ? "Request #{self.number}" : self.name
  end

  def request_label_with_id
    return self.name.blank? ? "Request #{self.number}" : "#{self.number}: " + self.name
  end

  # a convenience function to determine if a request should be cloned when added to a run
  # might become more elaborate later (i.e. from other stage, etc)
  def should_be_cloned?(target_stage_id = nil, new_run=true)
    # if it does not have a run, then does not need to be cloned for that reason
    return false unless new_run
    run_test = self.run.present?
    # if it has a different stage in its plan member or no member at all
    stage_test = self.plan_member.blank? ? false : self.plan_member.try(:plan_stage_id) != target_stage_id
    # if it is anything but planned or created
    aasm_state_test = !(self.created? || self.planned?)
    # if any of the tests are true, clone it
    return run_test || stage_test || aasm_state_test
  end

  def plan_label
    my_label = []
    unless self.plan.nil?
      my_label << self.plan.name
      my_label << (self.plan_member.try(:plan_stage_id).to_i == 0 ? 'Unassigned' : self.plan_member.try(:stage).try(:name))
      my_label << self.plan_member.run.name unless self.plan_member.nil? or self.plan_member.run.nil?
    end
    return my_label.join(": ")
  end

  def common_components_installed_on_env_of_app(app_id)
    common_app = App.find(app_id)
    common_components = []
    app_components_ids = common_app.components.map(&:id)
    available_components.uniq.each do |comp|
      if app_components_ids.include?(comp.id)
        app_component = common_app.application_components.find_by_component_id(comp.id) if  common_app
        installed_component = environment.installed_components.find_by_application_component_id(app_component.id) if app_component
        common_components << comp if installed_component
      end
    end
    return common_components
  end

  def ordered_step_info
    ar = ["id","number","sort_order","position"]
    steps.map{ |s| [s.id, s.number, s.number_real, s.position] }.sort{ |a,b| a[2] <=> b[2] }.insert(0,ar)
  end


  def update_properties
    temporary_current_property_values.each do |temp_val|
      temp_val.original_value_holder.update_property_value_for temp_val.property, temp_val.value
      temp_val.deleted_at = Time.now
      temp_val.save
    end
  end

  def ordered_step_ids
    steps.map{ |s| [s.id, s.number, s.number_real] }.sort{ |a,b| a[2][] <=> b[2][] }
  end


  # a convenience method for returning a cloned request after making a template behind the scenes
  def clone_via_template(requestor = User.current_user, request_params = {})
    # make the request into a template
    template = self.create_request_template
    if template
      # set up the parameters as if it was being created from a plan stage then clone it
      request = template.create_request_for(requestor, request_params.merge(request_template_id: template.id))
      template.delete
      request
    end
  end

  # create a template if needed from an existing request
  # FIXME: This code was copied from the controller in the interest of time; it
  # should be refactored here and in request_template_controller to be a single
  # create call in the model with the appropriate hooks and validations
  def create_request_template
    # state gets lost during request template save (complete goes to created)
    hold_state=self.aasm_state
    request_template = RequestTemplate.initialize_from_request(self, {name: "Clone for Request #{self.number}: #{Time.now.to_s(:long)}"})
    if request_template.save
      if self.aasm_state != hold_state
        # restore the state.
        self.update_column(:aasm_state, hold_state)
      end
      RequestTemplate.copy_from_request(self, request_template)
      return request_template
    else
      return nil
    end
  end

  def resolve_step_servers_association!
    request_steps = []
    steps_associations_to_include = [:request, :servers, :server_aspects, component_installed: [:servers, :server_aspects]]
    # otherwise we have N + 1 query
    InstalledComponent.without_finding_server_ids { request_steps = self.steps.includes(steps_associations_to_include) }

    transaction do
      begin
        request_steps.each do |step|
          if step.component_installed.present? && Step::ALLOWED_TO_REMOVE_SERVER.include?(step.aasm_state)
            server_ids_were         = step.servers.map(&:id)
            server_aspects_ids_were = step.server_aspects.map(&:id)
            server_ids              = step.component_installed.servers.map(&:id)
            server_aspects_ids      = step.component_installed.server_aspects.map(&:id)
            any_changes             = server_ids.sort != server_ids_were.sort || server_aspects_ids.sort != server_aspects_ids_were.sort

            next unless any_changes

            step.servers            = step.component_installed.servers
            step.server_aspects     = step.component_installed.server_aspects

            Step.without_auditing do
              Step.without_checking_installed_component { step.save(validate: false) }
            end
          end
        end
      rescue => e
        raise ActiveRecord::Rollback, e.backtrace
      end
    end
  end

  def resolve_procedures
    procedures.with_aasm_state('problem').each do |procedure|
      if procedure.steps.without_aasm_state('completed').count > 0
        procedure.lock!
      else
        procedure.complete_step!
      end
    end
  end

  # member of a plan stage for constraint purposes
  def has_plan_stage?
    true if plan_member && plan_member.plan_id && plan_member.plan_stage_id
  end

  def plan_stage_instance
    if has_plan_stage?
      PlanStageInstance.filter_by_plan_id(plan_member.plan_id).filter_by_plan_stage_id(plan_member.plan_stage_id).first
    end
  end

  # returns nil or an array of ConstraintValidationOutcome value objects if there are errors
  def plan_compliance_issues
    plan_stage_instance.try(:compliance_issues_for_item, self)
  end

  def start
    scheduled_at
  end

  def finish
    start + estimate.minutes
  end

  def has_notices?
    cached_notices.any?
  end
  alias :has_deployment_window_notices? :has_notices?

  def cached_notices
    @notices ||= notices
  end

  # user should be warned about future errors with dwe and related stuff on planning a request
  # determine the errors and return them as warnings/notices
  def notices
    preserve_errors do
      dw_validator  = RequestPolicy::DeploymentWindowValidator::Base.new(self, ignore_states: true)
      dw_validator.check_deployment_window_event
      self.errors.full_messages.compact.uniq
    end
  end

  def preserve_errors
    old_errors  = self.errors.dup
    self.errors.clear # so they are not messed up with new one

    result      = yield if block_given?

    self.instance_variable_set :@errors, old_errors
    result
  end

  def notice_messages
    cached_notices.join(".\n") unless cached_notices.empty?
  end
  alias :deployment_window_notices_message :notice_messages

  def find_application_package( package )
    app_with_package = apps.detect { | a | a.application_packages.find_by_package_id(package) }
    application_package = app_with_package.application_packages.find_by_package_id(package)
  end

  def available_package_ids
    apps.joins(:packages).pluck('packages.id')
  end

  def granter_type(user = nil)
    request_template_id.blank? ? :environment : :application
  end

  def check_compliance_and_dw_errors(environment_ids)
    return if environment_ids.blank?
    stitch_together_scheduled_at

    environment_ids.each do |env_id|
      self.environment_id = env_id
      check_deployment_window_event
      request_compliance if plan_member.present?
    end
  end

  def get_environment_names
    return '' if environment_ids.blank?
    Environment.id_equals(environment_ids).pluck(:name).join(', ')
  end

  private

  def self.find_in_order_of(request_ids)
    requests = find request_ids
    request_ids = request_ids.map(&:to_s)
    ordered_requests = []
    requests.each do |request|
      index = request_ids.index(request.id.to_s)
      ordered_requests[index] = request
    end
    ordered_requests.compact
  end

  # this before destroy function clears the plan member if it exists so we don't leave orphans in runs and stages
  def remove_plan_member
    self.plan_member.destroy if self.plan_member
  end

  def nullify_child_relation
    child = self.class.where(parent_request_id: id).first
    child.update_attribute(:parent_request_id, nil) if child.present?
    true
  end

  def sync_email_recipients(type, ids)
    type = type.to_s.camelize

    current_ids = email_recipient_ids_for(type)

    (ids - current_ids).each do |new_id|
      email_recipients.create(recipient_id: new_id, recipient_type: type) unless new_id.nil_or_empty?
    end

    (current_ids - ids).each do |unused_id|
      email_recipients.find_by_recipient_id_and_recipient_type(unused_id, type).destroy
    end
  end

#  def existence_of_an_app
#    if !apps || apps.empty?
#      errors.add("Request cannot be created without an application. Please specify an application")
#    end
#  end

  def env_not_in_environments
    apps.any? do |app|
      if app && environment && app.name != '[default]'
        app_environment_ids = app.environment_ids
        !app_environment_ids.flatten.include?(environment_id)
      end
    end
  end

  def app_environment_association_validation
    if env_not_in_environments
      errors.add(:base, I18n.t(:'request.validations.environment_not_associated'))
    end
  end

  def validate_additional_email_address
    email_match = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
    additional_email_addresses.each do |email|
      self.errors[:base] << "#{email} is invalid email address." if email_match.match(email).nil?
    end
  end

  def reformat_dates_to_us_format
    @target_completion_at_date = reformat_date(@target_completion_at_date) unless @target_completion_at_date.blank?
    @scheduled_at_date = reformat_date(@scheduled_at_date) unless @scheduled_at_date.blank?
  end

  def ensure_environment
    if environment.blank?
      self.environment_id = Environment.find_or_create_default.id
    end
  end

  def save_application_associations
    apps_request      = AppsRequest.where(request_id: id)
    existing_app_ids  = apps_request.pluck('app_id')
    new_app_ids       = apps.blank? ? [App.find_or_create_default.id] : apps.map(&:id)

    apps_requests_ids_to_delete = existing_app_ids - new_app_ids
    apps_requests_ids_to_create = new_app_ids - existing_app_ids

    apps_request.where(app_id: apps_requests_ids_to_delete).destroy_all if apps_requests_ids_to_delete.any?
    apps_requests_ids_to_create.each { |app_id| AppsRequest.find_or_create_by_request_id_and_app_id(id, app_id) }
  end

  def update_step_script_arguments
    logger.info "SS__ update stepargs: envchange? #{environment_id_changed?.to_s}"
    if (environment_id_changed? || app_id_changed?) && !new_record?
      steps.each do |step|
        logger.info "SS__ doingSteps: #{step.name}, comp: #{step.component_id.to_s}"
        next unless step.installed_component
        options = {"environment" => environment.id_change, "app" => app_id_change}
        step.update_script_arguments!(options)
      end
    end
  end

  # Change servers associated with steps through installed component of step if request environment is changed
  def change_server_selections!
    #logger.info "SS_Changing Servers"
    lookup = { 'Server' => :server_ids,
               'ServerGroup' => :server_group_ids,
               'ServerAspect' => :server_aspect_ids }
    steps_with_ic = steps.top_level.includes(:request, :servers, :server_groups, :server_aspects)
    steps_with_ic.each do |step|
      installed_component = step.installed_component_only
      next unless installed_component
      step.servers.clear
      step.server_groups.clear
      step.server_aspects.clear
      servs = installed_component.server_associations
      unless servs.size == 0
        step.update_attribute(lookup[servs.first.class.to_s], installed_component.server_association_ids)
      end
    end
  end

  def add_blank_steps
    step_components = Component.all(conditions: {id: used_components })
    step_components.each do |sc|
      step = self.steps.build(component_id: sc.id, owner_id: self.user_id, owner_type: "User")
      step.save!
    end
    self.steps
  end

  def request_link(request_number)
    request = "<a href = 'requests/#{request_number}'>#{request_number}</a>"
  end

  def add_entry_to_plan_env_app_dates
    self.app_ids.each do |app_id|
      if app_id != 0
        p = PlanEnvAppDate.where("app_id = ? and environment_id = ? and plan_id = ?",
                                 app_id,
                                 self.environment_id,
                                 self.plan_member.plan_id)
        PlanEnvAppDate.create(app_id: app_id,
                              environment_id: self.environment_id,
                              plan_id: self.plan_member.plan_id,
                              plan_template_id: '1' ,
                              created_at: Time.now,
                              created_by: User.current_user.try(:id) ||
                                             User.root_users.first.try(:id)) if (p.count == 0)
      end
    end
  end

  def validate_aasm_event
    self.executable_event ||= AasmEvent::ExecuteEvent.new(self)
    self.executable_event.validate_aasm_event
  end

  # if an aasm_event was passed through parameters on an update or create with no errors, then run it
  def run_aasm_event
    # make sure the is a command waiting to run and there are no errors on it.
    self.executable_event.run_aasm_event if self.errors[:aasm_event].blank?
  end

  # Checks if there is a plan, plan_stage, psi, and finally asks the PSI if this is compliant environment
  def request_compliance
    issues = plan_compliance_issues
    if issues.present?
      self.errors.add(:base, issues.map(&:message).try(:to_sentence))
    end
  end

  def check_for_strict_plan_control
    app = apps.first
    if !has_plan_stage? && app && app.try(:strict_plan_control)
      self.errors.add( :base, I18n.translate(:strict_plan_control_error, app_name: self.app_name.to_sentence) )
    end
  end

  def check_if_able_to_create_request
    return if app_ids.blank? || !environment_id_changed?
    if !User.current_user.root? && find_assigned_apps(User.current_user).blank?
      errors.add( :base, I18n.translate(:request_on_env_error_permissions, environment_name: environment_name) )
    end
  end

  def delete_associated_tickets
    return if steps.blank? || !plan_member.present?
    steps.each do |step|
      step.tickets.delete_all if step.tickets
    end if plan_member.plan_id_changed?
  end

  def check_deployment_window_event
    policy = RequestPolicy::DeploymentWindowValidator::Base.new self
    policy.check_deployment_window_event
  end

  def increment_counter_in_events
    deployment_window_event.increment! :requests_count if deployment_window_event_id?
  end

  def increment_counter_in_series
    deployment_window_event.series.increment! :requests_count if deployment_window_event_id?
  end

  # TODO: consider to move it to RequestPolicy::DeploymentWindowValidator else delete this comment
  def check_dws
    if deployment_window_event_id?
      dwe = DeploymentWindow::Event.where(id: self.deployment_window_event_id).first
      unless dwe && dwe.series
        self.deployment_window_event_id = nil
      end
    end
  end

  def scheduled_at_correct
    unless scheduled_at.present? && scheduled_at.future?
      errors.add(:base, 'Planned start should be present and point to future date')
    end
  end

  def should_be_scheduled
    if auto_start && (auto_start_changed? || scheduled_at_changed?)
      [:planned, :hold].include?(aasm.current_state)
    end
  end

  def schedule_auto_start
    ScheduledJob.schedule(self, User.current_user)
  end

  def should_be_unscheduled
    !auto_start && auto_start_changed? # && scheduled_jobs.present? > 0
  end

  def unschedule_auto_start
    ScheduledJob.unschedule(self)
  end

  def schedule_from_state
    schedule_auto_start if auto_start
  end

  def self.get_text_criteria
    text_columns = %w(nt.content requests.description requests.wiki_url)
    condition = MsSQLAdapter ? 'OR (LOWER(CAST(%s AS VARCHAR)) LIKE ?)' : 'OR (LOWER(%s) LIKE ?)'
    text_columns.map{|x| condition % x }.join(' ')
  end

  def possibility_to_auto_start
    if check_permissions && User.current_user.cannot?(:auto_start, self)
      errors.add(:base, I18n.t('request.validations.permit_auto_promote'))
    end
  end

  def is_visible_for_non_root?(user, user_app_ids)
    (app_ids.blank? || user_apps_has_request_apps?(user_app_ids)) && visible_if_created?(user)
  end

  def user_apps_has_request_apps?(user_app_ids)
    (user_app_ids & app_ids).any?
  end

  def visible_if_created?(user)
    !created? || user.can?(:view_created_requests_list, self)
  end

  def app_envs_memo_key
    "#{environment_id}|#{app_ids.first}"
  end

  def ensure_aasm_state_present
    if aasm_state.nil?
      self.aasm_state = :created
    end
  end
end
