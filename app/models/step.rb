################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class Step < ActiveRecord::Base
  # all states:
  # locked, ready, in_process, blocked, problem, being_resolved, complete
  ALLOWED_TO_REMOVE_SERVER = %w(locked ready blocked problem being_resolved)
  REQUEST_STATES_TO_EDIT_STEP = [:planned, :created, :hold, :cancelled]
  STEP_TABS = %w(general automation notes documents properties server_properties content) # design cant be default, nor notes
  STEP_TYPES = %w(normal request_input promotion)
  RELATED_OBJECT_TYPES = [:component, :package]
  DESIGN_STATES = ['locked']

  attr_accessible :aasm_state, :app_id, :bladelogic_password, :bladelogic_role,
                  :category_id, :complete_by, :completion_state,
                  :component_id, :component_version,
                  :description, :different_level_from_previous, :estimate,
                  :execute_anytime, :installed_component_id, :location_detail,
                  :manual, :name, :own_version, :owner_id, :owner_type,
                  :package_template_id, :package_template_properties, :parent_id,
                  :phase_id, :position, :procedure, :procedure_id, :ready_at,
                  :request_id, :runtime_phase_id, :script_id,
                  :script_type, :should_execute, :start_by, :token, :upload_attributes,
                  :version_tag_id, :work_finished_at, :work_started_at, :work_task_id,
                  :insertion_point, :created_at, :updated_at, :frozen_owner, :frozen_component,
                  :frozen_work_task, :frozen_automation_script, :frozen_bladelogic_script, :owner, :version, :uploads_attributes, :estimate_hours,
                  :estimate_minutes, :start_by_date, :start_by_hour, :start_by_minute, :start_by_meridian,
                  :complete_by_date, :complete_by_hour, :complete_by_minute, :complete_by_meridian, :temp_component_id,
                  :note, :server_ids, :server_aspect_ids, :rerun_script, :request, :ticket_ids,
                  :change_request_id, :custom_ticket_id, :on_plan, :release_content_item_id, :execution_condition,
                  :default_tab, :execute_on_plan, :executor_data_entry, :suppress_notification,
                  :allow_unattended_promotion, :protected_step, :step_type, :package_id, :package_instance_id,
                  :latest_package_instance, :create_new_package_instance, :related_object_type, :step_references,
                  :reference_ids, :aasm_event, :protect_automation_tab

  include ExposedTime
  include StepContainer
  include Messaging
  include FilterExt

  acts_as_messagable
  acts_as_stomplet_eventable 'request_id', StepStompletRenderer.new

  concerned_with :step_state_machine, :import_step, :export_step_resource_automation_script
  concerned_with :script_argument_validations

  # start cleaning the attributes
  normalize_attributes :component_version

  extend AssociationFreezer::ModelAdditions

  #CHCKME:This does not seem to be used anywhere and breaks the migrations.
  #EventsForCategories = List.get_list_items("EventsForCategories")

  expose_time_for_selector :complete_by, :start_by
  before_validation :stitch_together_complete_by, :stitch_together_start_by, :generate_estimate, :unless => :should_not_time_stitch #:reformat_dates_to_us_format,

  after_update :run_aasm_event, :if => Proc.new { |s| s.aasm_event.present? }

  attr_accessor :temp_component_id, :run_now, :reference_ids, :aasm_event

  before_save :stitch_package_template_id, :check_installed_component, :remove_execution_conditions

  after_create :move_into_position, :set_up_script_arguments!

  after_save :add_new_steps

  after_save :update_references!

  before_destroy :reorder_if_parallel_steps

  before_destroy :check_if_protected

  belongs_to :request, touch: true
  belongs_to :app
  belongs_to :parent, :class_name => 'Step'
  belongs_to :floating_procedure, :class_name => "Procedure", :foreign_key => 'procedure_id'
  belongs_to :owner, :polymorphic => true
  belongs_to :component
  belongs_to :automation_script, foreign_key: :script_id, class_name: 'Script'
  belongs_to :bladelogic_script, foreign_key: :script_id, class_name: 'BladelogicScript'
  belongs_to :work_task
  belongs_to :category
  belongs_to :phase
  belongs_to :runtime_phase
  belongs_to :package_template
  belongs_to :installed_component
  belongs_to :component_installed, class_name: 'InstalledComponent', foreign_key: :installed_component_id
  belongs_to :version_tag
  belongs_to :package
  belongs_to :package_instance

  enable_association_freezer

  has_one :execution_condition, class_name: 'StepExecutionCondition'
  has_one :environment, through: :request
  has_many :step_script_arguments, :dependent => :destroy
  has_many :script_arguments, :through => :step_script_arguments
  has_many :notes, :as => :object, :dependent => :destroy, :order => 'created_at ASC'
  has_many :logs, :class_name => 'ActivityLog', :order => 'created_at DESC, usec_created_at DESC'
  has_many :steps, :foreign_key => :parent_id, :dependent => :destroy, :order => 'position'
  has_many :temporary_property_values, :dependent => :destroy
  has_many :uploads, :as => :owner, :dependent => :destroy
  has_many :referenced_conditions, :class_name => 'StepExecutionCondition', :foreign_key => :referenced_step_id
  has_many :linked_items, :as => :target_holder, :dependent => :destroy
  has_many :tickets, :through => :linked_items, :as => :source_holder, :source => :source_holder, :source_type => 'Ticket'
  has_many :step_holders, :dependent => :destroy
  has_many :available_components, through: :environment, conditions: ->(*args, &block) { ['application_components.app_id = ?', self.app_id] }
  has_many :installed_components, through: :environment, conditions: ->(*args, &block) { ['application_environments.app_id = ?', self.app_id] }
  has_many :step_references, :dependent => :destroy
  has_and_belongs_to_many :servers
  has_and_belongs_to_many :server_groups
  has_and_belongs_to_many :server_aspects

  # FIXME: Many of the relationships between steps and child objects are not specified
  # and do not have proper cascade delete or restricts.  Here, I don't want to lose job
  # run history, so I think restrict is the proper choice.  Agree?
  has_many :job_runs, :dependent => :nullify

  accepts_nested_attributes_for :uploads, :reject_if => lambda { |a| a[:attachment].blank? && a[:new_attachment].blank? }, :allow_destroy => true

  acts_as_list :scope => "(\#{acts_as_list_scope})"

  acts_as_audited :except => [:frozen_owner,
                              :frozen_component,
                              :frozen_automation_script,
                              :frozen_bladelogic_script,
                              :frozen_work_task]

  validates :script, :presence => {:if => Proc.new { |s| s.auto? && s.script_type != "BladelogicScript" }}

  validates :owner, :presence => {:unless => :procedure?}

  validates :name, :length => {:maximum => 255}

  validate :has_exactly_one_parent

  validate :validate_aasm_event, :if => Proc.new { |s| s.aasm_event.present? }

  attr_accessor :note, :state_changer, :ignore_current_script_arguments, :rerun_script,
                :base_url, :selected_step_arguments, :should_not_time_stitch,
                :executable_event
  #attr_protected :procedure

  # Steps created for request from request_template have malformed value;
  # This is because we use mass insert 'Step.import' when creating steps from
  # request_template which generates raw sql;
  # As a result `package_template_properties` which is a clob type is wrongly
  # parsed when inserting and then can't be populated correctly
  # So, for now, Hash type was removed. Actual result would be a String
  # If this breaks something, add `steps.update_all(package_template_properties: {})`
  # to the end of `bulk_create_steps` methods in request_template and revert this
  serialize :package_template_properties #, Hash

  scope :next_step, lambda { |request_id, step_id| where(" request_id = ? and position > (select position from steps where id = ? ) ", request_id, step_id).order("position asc").limit(1) }

  scope :completed_in_last_n_seconds, lambda { |current_time, elapsed| where("updated_at >= ? and steps.#{PROCEDURE_COLUMN} = ?", (current_time - elapsed), false).order("position asc") }

  scope :owned_by_user, lambda { |user_id| where(:owner_id => user_id, :owner_type => "User") }

  scope :owned_by_group, lambda { |group_id| where(:owner_id => group_id, :owner_type => "Group") }

  scope :id_equals, lambda { |ids|
    where(:id => ids)
  }

  def self.owned_by_user_including_groups(user_id)
    # user_owned_ids = Step.owned_by_user(user_id).pluck(:id)
    # group_ids = UserGroup.where(:user_id => user_id).pluck(:group_id)
    # group_owned_ids = group_ids.inject([]) { |ids, group_id| ids += Step.owned_by_group(group_id).pluck(:id) }
    # where(:id => (user_owned_ids | group_owned_ids))

    where("steps.id IN " +
              "(SELECT steps.id FROM steps WHERE steps.owner_id IN ( #{user_id.join(", ")} ) AND steps.owner_type = 'User' GROUP BY steps.id) " +
              "OR steps.id IN " +
              "(SELECT steps.id FROM steps where steps.owner_id IN " +
              "(SELECT user_groups.group_id FROM user_groups WHERE user_groups.user_id IN ( #{user_id.join(", ")} ) GROUP BY user_groups.group_id) " +
              "AND steps.owner_type = 'Group' GROUP BY steps.id) ")
  end

  scope :running, where("steps.aasm_state IN ('in_process','problem','ready')")
  scope :ready_or_in_process, where("steps.aasm_state IN ('in_process', 'ready')")
  scope :problem, where(:aasm_state => 'problem')
  scope :all_currently_running, ->(user) do
    all_running = running.request_in_progress.where(procedure: false)
    unless user.root?
      all_running = all_running.where(
          ( arel_table[:owner_id].eq(user.id).and(arel_table[:owner_type].eq(User.name)) ).
              or( arel_table[:owner_id].in(user.group_ids).and(arel_table[:owner_type].eq(Group.name)) ).
              or( arel_table[:app_id].in(user.app_ids) )
      )
    end
    all_running
  end

  STEP_TYPES.each do |type|
    define_method "#{type}?" do
      self.step_type == type
    end
  end

  def has_package?
    related_object_type == "package" && package.present?
  end

  def package_is_not_in_list(available_packages)
    if package.present?
      !available_packages.include?(package.id)
    else
      false
    end
  end

  def has_invalid_package?
    if parent_object.present?
      app_package_ids = parent_object.apps.joins(:packages).pluck('packages.id')
      package.present? && !app_package_ids.include?(package.id)
    else
      false
    end
  end

  def has_component?
    related_object_type == "component"
  end

  def protected?
    if self.procedure?
      self.steps.any? { |step| step.protected? }
    else
      self.protected_step
    end
  end

  def protect_automation?
    (!self.procedure?) && self.protect_automation_tab
  end

  def check_if_protected
    if self.protected?
      self.errors[:base] << 'Step is protected and cannot be deleted'
      false
    else
      true
    end
  end

  def not_movable?
    if procedure?
      self.steps.any? { |step| step.active_done? } || protected?
    else
      active_done? || protected?
    end
  end

  def active_done?
    self.aasm_state.to_sym.in? [:in_process, :complete]
  end

  def self.in_app(app)
    app_id = app.is_a?(App) ? app.id : app
    Step.joins(request: :apps_requests).where('apps_requests.app_id = ?', app_id)
  end

  scope :with_component_ids, lambda { |component_ids| where(:component_id => component_ids) }

  def self.in_environment(environment)
    environment_id = environment.is_a?(Environment) ? environment.id : environment
    Step.includes(:request).where('requests.environment_id = ?', environment_id)
  end

  scope :with_server_ids, lambda { |server_ids| includes(:servers).extending(QueryHelper::WhereIn).where_in('servers.id', server_ids) }
  scope :with_server_aspect_ids, lambda { |server_aspect_ids| includes(:server_aspects).extending(QueryHelper::WhereIn).where_in('server_aspects.id', server_aspect_ids) }
  scope :in_completed_request, includes(:request).where("requests.aasm_state = 'complete'")
  scope :request_in_progress, includes(:request, :component, :servers, :work_task).where("requests.aasm_state NOT IN (?)", %w(deleted cancelled complete))
  scope :should_execute, where(:should_execute => true)

  scope :top_level, where("steps.parent_id IS NULL").order('steps.position')
  #FIXME:DELETE_ME
  #named_scope :sort_by_parent_position, :order => 'steps.parent_id , steps.position '

  #FIXME:TEST_ME
  scope :sort_by_parent_position, order('steps.parent_id , steps.position')

  scope :atomic, where(:procedure => false)

  scope :component_versions, lambda { |component_id| where(:component_id => component_id).order('steps.id desc') }
  scope :own_component_versions, lambda { |component_id| where(:component_id => component_id, :own_version => true) }

  #
  # Weirdly named scope
  # First of all, it does not get all the attributes
  # Secondly, it is only picking up steps within min id of all steps that belong to specified component
  scope :group_by_components, where('component_id IS NOT NULL').select('component_id, min(id) as id').group('component_id')

  scope :anytime_steps, where(:execute_anytime => true)

  scope :order_by_position, order('steps.position ASC')

  scope :order_by_component_name, includes(:component).order('components.name ASC')

  scope :serial_steps, where(:different_level_from_previous => true)

  scope :parallel_steps, where(:different_level_from_previous => false)

  scope :find_procedure, where(:procedure => true)

  # a named scope for getting version conflicts related to a run
  # oracle and postgres treat blank and null a little differently, so
  # this and statement was failing on oracle.
  #(TRIM(steps.component_version) IS NOT NULL AND TRIM(steps.component_version) != '')
  scope :version_conflicts_for_run, lambda { |run_id|
    includes(:component).includes(:app).includes(:request => [:plan_member, :environment, :requestor]).
        where("plan_members.run_id = ? AND 0 < #{DB_STRLEN}(steps.component_version)", run_id).
        order("apps.name ASC, environments.name ASC, components.name ASC, steps.component_version")
  }

  # new filters

  # capitalized as proper constants and expanded list of id scopes
  COLUMNS_FOR_NAMED_SCOPES = %w(request_id installed_component_id component_version version_tag_id custom_ticket_id package_template_id script_id runtime_phase_id phase_id procedure_id parent_id category_id work_task_id)
  COLUMNS_FOR_NAMED_SCOPES.each { |id_column|
    scope "with_#{id_column}".to_sym, lambda { |given_id| where("steps.#{id_column}" => given_id) }
  }

  scope :with_name, lambda { |name| where(["LOWER(steps.name) = ?", name.downcase]) }
  scope :with_aasm_state, lambda { |values| where(["LOWER(steps.aasm_state) IN (?)", [values].flatten.map(&:downcase)]) }
  scope :without_aasm_state, lambda { |value| where(["LOWER(steps.aasm_state) <> ?", value.downcase]) }

  scope :used_in_deleted_requests, joins(:request).where('requests.aasm_state = ? ', 'deleted')

  # new common filter function for steps
  is_filtered cumulative_by: {name: :with_name,
                              aasm_state: :with_aasm_state,
                              component_id: :with_component_ids,
                              request_id: :with_request_id,
                              installed_component_id: :with_installed_component_id,
                              component_version: :with_component_version,
                              version_tag_id: :with_version_tag_id,
                              custom_ticket_id: :with_custom_ticket_id,
                              package_template_id: :with_package_template_id,
                              script_id: :with_script_id,
                              runtime_phase_id: :with_runtime_phase_id,
                              phase_id: :with_phase_id,
                              procedure_id: :with_procedure_id,
                              parent_id: :with_parent_id,
                              category_id: :with_category_id,
                              work_task_id: :with_work_task_id,
                              server_id: :with_server_ids,
                              started_at_range: :with_started_at_dates},
              default_flag: :all,
              specific_filter: :step_specific_filters

  def self.step_specific_filters(entities, adapter_column, filters = {})
    if adapter_column.value_to_boolean(filters[:running])
      entities = entities.running
    end

    if filters[:user_id] || filters[:group_id]
      filtered_entities = entities.owned_by_user(filters[:user_id]) | entities.owned_by_group(filters[:group_id]) # union search
      entities = entities.where(id: filtered_entities)
    end

    entities
  end

  delegate :environment, :to => :request

  delegate :business_process_name, to: :request
  delegate :release_name, to: :request
  delegate :app_name, to: :request
  delegate :environment_name, to: :request
  delegate :created?, to: :request, prefix: true, allow_nil: true
  delegate :plan, to: :request, allow_nil: true
  delegate :number, to: :request, prefix: true
  delegate :name, to: :component, prefix: true, allow_nil: true
  delegate :name, to: :phase, prefix: true, allow_nil: true
  delegate :name, to: :work_task, prefix: true, allow_nil: true
  delegate :name, to: :owner, prefix: true, allow_nil: true
  delegate :contact_number, to: :owner, prefix: true, allow_nil: true
  delegate :script_external_resource, to: :script, prefix: false, allow_nil: true

  class << self
    def search(keyword)
      if PostgreSQLAdapter || OracleAdapter
        user_name = "users.first_name || ' ' || users.last_name"
      elsif MsSQLAdapter
        user_name = "users.first_name + ' ' + users.last_name"
      end
      find_by_sql <<-SQL
        SELECT steps.id FROM steps
        WHERE steps.name LIKE '%#{keyword}%' OR LOWER(steps.aasm_state) = LOWER('#{keyword}')
        OR LOWER(steps.component_version) = LOWER('#{keyword}') OR steps.description LIKE '%#{keyword}%'
        UNION
        SELECT steps.id FROM steps
        LEFT JOIN users ON users.id = steps.owner_id AND steps.owner_type = 'User'
        WHERE #{user_name} LIKE '%#{keyword}%'
        UNION
        SELECT steps.id FROM steps
        LEFT JOIN groups ON groups.id = steps.owner_id AND steps.owner_type = 'Group'
        WHERE groups.name LIKE '%#{keyword}%'
        UNION
        SELECT steps.id FROM steps LEFT JOIN components ON components.id = steps.component_id
        WHERE LOWER(components.name) = LOWER('#{keyword}')
        UNION
        SELECT steps.id FROM steps LEFT JOIN work_tasks ON work_tasks.id = steps.work_task_id
        WHERE LOWER(work_tasks.name) = LOWER('#{keyword}')
        UNION
        SELECT steps.id FROM steps LEFT JOIN phases ON phases.id = steps.phase_id
        WHERE LOWER(phases.name) = LOWER('#{keyword}')
        UNION
        SELECT steps.id FROM steps LEFT JOIN runtime_phases ON runtime_phases.id = steps.runtime_phase_id
        WHERE LOWER(runtime_phases.name) = LOWER('#{keyword}')
        UNION
        SELECT steps.id FROM steps LEFT JOIN notes ON notes.step_id = steps.id
        WHERE notes.content LIKE '%#{keyword}%'
        UNION
        SELECT steps.id FROM steps LEFT JOIN procedures ON procedures.id = steps.procedure_id
        WHERE LOWER(procedures.name) = LOWER('#{keyword}') OR procedures.description LIKE '%#{keyword}%'
        UNION
        SELECT steps.id FROM steps LEFT JOIN categories ON categories.id = steps.category_id
        WHERE categories.name LIKE '%#{keyword}%'
        UNION
        SELECT steps.id FROM steps
        LEFT JOIN servers_steps ON servers_steps.step_id = steps.id
        LEFT JOIN servers ON servers_steps.server_id = servers.id
        WHERE LOWER(servers.name) LIKE LOWER('#{keyword}')
      SQL
    end

    def remove_servers_association!(server_ids, component_ids)
      affected_steps = self.with_server_ids(server_ids)
      affected_steps = affected_steps.where(:component_id => component_ids).where('request_id IS NOT ?', nil) if component_ids != :ignore_components

      ## deassociate servers from steps
      affected_steps.each do |step|
        if step.servers_can_be_deassigned?
          step_servers = step.server_ids.map { |id| id.to_s } - server_ids.map { |id| id.to_s }
          step.update_attribute(:server_ids, step_servers)
        end
      end

      return affected_steps

    rescue => e
      raise 'Could not deassign servers from step.' + e.message
    end

    def remove_server_aspects_association!(server_aspect_ids, component_ids)
      affected_steps = self.with_server_aspect_ids(server_aspect_ids)
      affected_steps = affected_steps.where(:component_id => component_ids).where('request_id IS NOT ?', nil) if component_ids != :ignore_components

      ## deassociate server_aspects from steps
      affected_steps.each do |step|
        if step.servers_can_be_deassigned?
          step_server_aspects = step.server_aspect_ids.map { |id| id.to_s } - server_aspect_ids.map { |id| id.to_s }
          step.update_attribute(:server_aspect_ids, step_server_aspects)
        end
      end

      return affected_steps

    rescue => e
      raise 'Could not deassign server aspects from step.' + e.message
    end

    def with_started_at_dates(options)
      params = options.symbolize_keys
      return scoped if params[:initial_date].blank? && params[:end_date].blank?

      params[:initial_date] = params[:initial_date].presence || (Date.today - 10.years).strftime('%m/%d/%Y')
      params[:end_date] = params[:end_date].presence || (Date.today + 10.years).strftime('%m/%d/%Y')

      start_date = Date.generate_from(params[:initial_date]).to_time.beginning_of_day.in_time_zone
      end_date = Date.generate_from(params[:end_date]).to_time.end_of_day.in_time_zone
      where(work_started_at: (start_date..end_date))
    end
  end

  def self.build_script_arguments_for(step_to, step_from, options = nil)
    return if step_to.manual?

    step_from.step_script_arguments.includes(:script_argument).map do |ssa|
      options["clone_argument_value"] = ssa.value unless options.nil?
      step_to.step_script_arguments.build({:script_argument_id => ssa.script_argument_id,
                                           :script_argument_type => ssa.script_argument_type,
                                           :value => [step_to.script_argument_property_value(ssa.script_argument, options)]
                                          })
    end
  end

  def servers_can_be_deassigned?
    (Step::ALLOWED_TO_REMOVE_SERVER.include? self.aasm_state) && (Request::ALLOWED_TO_REMOVE_SERVER.include? self.request.aasm_state)
  end

  # Patch to match expected params for
  # update_script
  # ! This should be refactored asap !
  def capistrano_script_id=(value)
    self.script_id = value
  end

  def capistrano_script_id
    self.script_id
  end

  def bladelogic_script_id=(value)
    self.script_id = value
  end

  def bladelogic_script_id
    self.script_id
  end

  def hudson_script_id=(value)
    self.script_id = value
  end

  def hudson_script_id
    self.script_id
  end

  # End of patch for update_script

  def properties
    component ? component.properties : []
  end

  def server_association_names
    return @ic_server_associations if @ic_server_associations
    @ic_server_associations = installed_component ? installed_component.server_association_names : []
  end

  def belongs_to?(user, exclude_requestors = false)
    members = []
    members = [self.request.owner, self.request.requestor] unless exclude_requestors
    members += [self.owner]
    members += self.owner.resources if self.owner.is_a?(Group)
    members.include? user
  end

  def user_owner?
    owner_type == 'User'
  end

  def group_owner?
    owner_type == 'Group'
  end

  def rerun_script?
    rerun_script == 'true'
  end

  def full_phase_name
    "#{phase.name}#{runtime_phase_name}" if phase
  end

  def runtime_phase_name
    ":#{runtime_phase.name}" if runtime_phase
  end

  def complete_or_not_executable?
    if procedure?
      return true if steps.all? { |s| s.complete_or_not_executable? }
      unless meets_execution_condition?
        return true
      end
    else
      if self.parent.nil?
        return true if complete?
        return true unless should_execute?
      else
        #let the parent procedure determine if the step has executed
        if self.parent.meets_execution_condition?
          return true if complete?
          return true unless should_execute?
        else
          return true
        end
      end
    end
    false
  end

  def meets_execution_condition?
    execution_condition.nil? || execution_condition.met?
  end

  def copy_execution_condition_to(other_step)
    return unless execution_condition
    other_step.execution_condition = execution_condition.dup
    execution_condition.constraints.each do |constraint|
      other_step.execution_condition.constraints << constraint.dup #.create(:constrainable_id => constraint.constrainable_id, :constrainable_type => constraint.constrainable_type)
    end
    # other_step.execution_condition.referenced_step = other_request.steps.select { |s| s.position == execution_condition.referenced_step.position && !s.procedure? }.first
  end

  def self.update_execution_condition(conds, other_request)
    steps = other_request.steps.includes(:execution_condition, :parent)
    steps.each do |step|
      if step.execution_condition.present?
        new_reference_step_number = conds[step.number]
        new_step = steps.select { |s| s.number == new_reference_step_number }.first
        step.execution_condition.referenced_step = new_step
        step.execution_condition.save
      end
    end
  end

  def execution_condition_image_and_title
    img = 'diamond-off.png'
    title = ''
    if execution_condition.present?
      cond_fail = condition_check_messages
      if cond_fail.present?
        img = 'diamond-warn.png'
        title = cond_fail
      else
        img = 'diamond-on.png'
        title = execution_condition_title
      end
    end
    [img, title]
  end

  def condition_check_messages
    result = []
    if execution_condition.present?
      execution_condition.condition_check_messages.each do |val_msg|
        result << val_msg.message
      end
    end
    result.join('\n')
  end


  def execution_condition_title
    if self.execution_condition
      cond = self.execution_condition
      case cond.condition_type
        when 'property'
          "Property condition\nStep: #{cond.referenced_step.name}\nProperty name: #{cond.property.name}\nValue: #{cond.value}"
        when 'runtime_phase'
          "Runtime phase condition\nStep: #{cond.referenced_step.name}\nRuntime phase: #{RuntimePhase.find(cond.runtime_phase_id).name}"
        when 'environments'
          "Environment(s) condition\nEnvironment(s): #{cond.environments.map(&:name).join(', ')}"
        when 'environment_types'
          "Environment type(s) condition\nEnvironment type(s): #{cond.environment_types.map(&:name).join(', ')}"
        else
          'Unknown condition type'
      end
    else
      'No condition'
    end

  end

  def copy_script_arguments_to(other_step, options = nil)
    #def copy_script_arguments_to(other_step, other_request, new_environment_id = nil)
    return if other_step.manual?

    self.step_script_arguments.includes(:script_argument).each do |ssa|
      #:value => safe_copy_script_argument(ssa, new_environment_id, other_step)
      options["clone_argument_value"] = ssa.value unless options.nil?
      other_step.step_script_arguments.create({:script_argument_id => ssa.script_argument_id,
                                               :script_argument_type => ssa.script_argument_type,
                                               :value => [other_step.script_argument_property_value(ssa.script_argument, options)]
                                              })
      clear_output_step_script_arguments(other_step)
    end
  end

  # handle different environments with their own script values
  # which should override any local settings
  def safe_copy_script_argument(script_argument, new_environment_id, other_step = nil)
    # Need to handle mapped in one env and not in another cannot pass a mapped value as if it was custom
    #logger.info "SS__ SafeCopy: #{new_environment_id.to_s}, arg: #{script_argument.inspect}"
    if (new_environment_id.nil? || self.request.environment_id == new_environment_id) && !script_argument.value.nil?
      # if the environments are the same, set the value from the original step including custom text
      value = script_argument.try(:value)
    else
      # current property mapping if any
      mapped_property = script_argument.script_argument.properties.first
      #logger.info "SS__ MappedProp: #{mapped_property.try(:name)}"
      if mapped_property.nil?
        # there is no mapping, so any value must be custom
        value = script_argument.value
      else
        # get any value that might have been mapped through an installed component
        #logger.info "SS__ ScriptArgs: Value: #{value}, SrcStep: #{id.to_s}, IC: #{installed_component.id.to_s}, Prop: #{mapped_property.try(:name)}, oldVal: #{script_argument.value}"
        unless self.installed_component.nil?
          associated_value = (other_step.nil? ? self : other_step).installed_component.associated_current_property_values.find_by_property_id(mapped_property.id).try(:value)
          if associated_value.nil?
            # set it to the current custom value
            value = script_argument.value
          else
            mapped_value = associated_value
            # compare them and discard it if the are equal because that will mean it is a mapped value not custom
            if mapped_value != script_argument.try(:value)
              # clear the value
              value = mapped_value
            end
          end
        end
      end
    end
    value
  end

  def script_argument_value(argument_id)
    return if ignore_current_script_arguments
    script_arg = step_script_arguments.find_by_script_argument_id(argument_id)
    script_arg.value if script_arg
  end

  def script_argument_property_value(argument, options = nil)
    # options can be the params object from the request form or the argument hash from step form
    #argument is script.argument, not step_script_argument
    return nil if installed_component.nil? && package.nil?
    form_value, old_property_value = nil, nil
    step_value = script_argument_value(argument.id)
    values_from_properties = argument.values_from_properties(installed_component)
    property_value = values_from_properties.first if values_from_properties.size == 1
    # if the environment or app changed or form saved
    if options.nil?
      new_value = step_value.blank? ? property_value : step_value
    else
      form_value = options[:argument][argument.id.to_s] unless options[:argument].nil? # step update change
      if form_value.blank? # Coming from request change or new from template
        step_value = options["clone_argument_value"] if options.keys.include?("clone_argument_value") && !options["clone_argument_value"].blank?
        unless options["old_environment_id"].nil? && options["old_app_id"].nil?
          old_env_id = options["old_environment_id"].nil? ? request.environment_id : options["old_environment_id"]
          old_app_id = options["old_app_ids"].nil? ? app_id : options["old_app_ids"]
          # is it a custom value and not a mapped value from a different environment
          old_ic = InstalledComponent.find_by_app_comp_env(old_app_id, component_id, old_env_id)
        end
        old_ic = InstalledComponent.find(options[:old_installed_component_id]) if options.keys.include?(:old_installed_component_id) && options[:old_installed_component_id].to_i > 0
        if old_ic
          old_values_from_properties = argument.values_from_properties(old_ic)
          old_property_value = old_values_from_properties.first if old_values_from_properties.size > 0
        end
        new_value = step_value.blank? ? property_value : step_value
        #logger.info "SS__ SA-PropVal: new: #{new_value}"
        # If options are sent, app or environment has changed thus can't keep an old prop value
        if old_property_value == new_value
          new_value = property_value || ''
        end
      end
    end
    new_value = form_value unless form_value.nil?
    #logger.info "SS__ SA-PropVal: Setting: [#{argument.id.to_s}]-#{new_value} - choices: Form: #{form_value}, step: #{step_value}, prop: #{property_value}, ic: #{installed_component.id}, old: #{old_property_value}, options: #{options.inspect}"
    new_value
  end

  def script_argument_values_display(options = nil)
    return if script.nil?
    result = {}
    script.arguments.each do |argument|
      result[argument.id] = {
          "id" => argument.id,
          "argument" => argument.argument,
          'script_arguments' => script.arguments,
          "name" => argument.name,
          "value" => script_argument_property_value(argument, options),
          "type" => (script_type == "BladelogicScript" ? script.script_type : script.automation_category)
      }
    end
    result
  end

  def respond_to_app_env_change(request_params)
    new_attrs = {}
    new_attrs[:app_id] = get_app_id(request_params)
    new_attrs[:installed_component_id] = get_installed_component(request_params).try(:id)

    if GlobalSettings.limit_versions?
      # Rajesh Jangam: BNP Changes 05/11/2012
      # Structured versions, Clyde said -> Keep versions only in case matching version found in new environment
      if version_tag
        v = nil
        if new_attrs[:installed_component_id]
          v = VersionTag.find_by_name_and_installed_component_id(version_tag.name, new_attrs[:installed_component_id]) rescue nil
        end
        if v
          # Matching version found
          new_attrs[:version_tag_id] = v.id
          new_attrs[:component_version] = v.name
        else
          # No matching version found
          new_attrs[:version_tag_id] = nil
          new_attrs[:component_version] = nil
        end
      end
    else
      # Rajesh Jangam: BNP Changes 05/11/2012
      # Unstructured versions, We will keep the version only in case corresponding installed component found
      # Which means that matching component found in the other app/env
      unless new_attrs[:installed_component_id]
        new_attrs[:component_version] = nil
      end
    end
    #logger.info "SS__ RespondToAppChg: #{request_params.inspect}"
    self.update_attributes(new_attrs)
    update_script_arguments!(request_params)
  end

  def update_script_arguments!(options = nil)
    return if manual? || (installed_component.nil? && package.nil?)
    arguments_hash = {}
    step_script_argument_hash = {} # This is done to make the uploads for step argument pointed to right id
    self.script.arguments.each do |argument|
      new_value = self.script_argument_property_value(argument, options)
      arguments_hash[argument.id] = new_value
      #logger.info "SS__ ScriptArgs: Old: #{step_value}, New: #{new_value}, SrcStep: #{id.to_s}, IC: #{installed_component.id.to_s}, options: #{options.inspect}"
    end

    self.step_script_arguments.each do |step_argument|
      if step_argument.uploads.present?
        upload_record = step_argument.uploads.find_by_owner_id_and_owner_type(step_argument.id, 'StepScriptArgument')
        if upload_record.present?
          step_script_argument_hash[step_argument.id] = {step_id: step_argument.step_id, script_argument_id: step_argument.script_argument_id}
        end
      end
    end

    self.step_script_arguments.destroy_all

    arguments_hash.each do |arg_id, value|
      if script_type == 'BladelogicScript'
        argument = "#{script_type}Argument".constantize.find(arg_id) rescue nil
        value = [value].flatten
      else
        argument = ScriptArgument.find(arg_id) rescue nil
        if argument && value.present? && [value].flatten.first.present?
          if argument.argument_type == 'in-datetime'
            argument_datetime = [value].flatten.first
            argument_date = argument_datetime.split(' ')[0]
            argument_time = argument_datetime.split(' ')[1]
            reformated_argument_date = reformat_date_for_save(argument_date)
            value = "#{reformated_argument_date} #{argument_time}"
          elsif argument.argument_type == 'in-date'
            argument_date = [value].flatten.first
            reformated_argument_date = reformat_date_for_save(argument_date)
            value = reformated_argument_date
          end
        end
        value = [value].flatten
      end
      self.step_script_arguments.create!(:script_argument => argument, :value => value) if argument
    end

    step_script_argument_hash.each do |id, hash|
      new_step_script_id = StepScriptArgument.find_by_step_id_and_script_argument_id(hash[:step_id], hash[:script_argument_id])
      old_upload = Upload.find_by_owner_id_and_owner_type(id, 'StepScriptArgument')
      old_upload.update_attribute(:owner_id, new_step_script_id.id)
    end

  end

  # This code is duplicate of ApplicationController#reformat_date_for_save method
  # TODO: Use same methods present in ApplicationController#reformat_date_for_save
  def reformat_date_for_save(date_string)
    return if date_string.nil?
    month = "1"
    day = "1"
    year = "1900"
    #match = date_string.gsub("-","/").match(/(\d+)\/|\-(\d+)\/|\-(\d+)/)
    match = date_string.gsub("-", "/").split("/")
    month_numbers = {"Jan" => "1", "Feb" => "2", "Mar" => "3", "Apr" => "4", "May" => "5", "Jun" => "6",
                     "Jul" => "7", "Aug" => "8", "Sep" => "9", "Oct" => "10", "Nov" => "11", "Dec" => "12"}
    format_codes = GlobalSettings[:default_date_format].gsub("-", "/").gsub(" ", "/").split("/")
    format_codes.each_with_index do |fmt, idx|
      case fmt.downcase
        when '%m'
          month = match[idx]
        when '%d'
          day = match[idx]
        when '%y'
          year = match[idx]
        when '%b'
          month = month_numbers[match[idx]]
      end
    end
    "#{year}-#{month}-#{day}"
  end

  # This method overrides the belongs_to association as step can now be associated to two types of scripts
  # def script(options={})
  #   return unless script_id
  #   select_fields = options.fetch(:select, false)
  #
  #   if script_type == 'BladelogicScript'
  #     if select_fields
  #       BladelogicScript.select(select_fields).find(script_id) rescue nil
  #     else
  #       @script ||= BladelogicScript.find(script_id) rescue nil
  #     end
  #   else
  #     if select_fields
  #       Script.select(select_fields).find(script_id) rescue nil
  #     else
  #       @script ||= Script.find(script_id) rescue nil
  #     end
  #   end
  # end

  def script(options={})
    if script_type == 'BladelogicScript'
      bladelogic_script
    else
      automation_script
    end
  end


  def script=(script)
    self.script_id = script.try(:id)
  end

  def set_up_script_arguments!
    return if script.nil? || ignore_current_script_arguments
    arguments_hash = {}
    unless script.arguments.blank?
      script.arguments.each do |arg|
        arguments_hash[arg.id] = arg.values_from_properties(self.installed_component).first
      end
      update_script_arguments!(arguments_hash)
    end
  end

  def server_level
    server_aspects.first.server_level unless server_aspects.empty?
  end

  def estimate_hours=(new_est)
    @estimate_hours = new_est.to_i
    logger.info @estimate_hours
  end

  def estimate_minutes=(new_est)
    @estimate_minutes = new_est.to_i
  end

  def number
    num = ''
    num << "#{parent.position}." if parent
    num << "#{position}"
  end

  def number_real
    frac = parent_id ? position * 0.001 : 0
    pos = parent_id ? parent.position : position
    pos + frac
  end

  def insertion_point=(position)
    if new_record?
      @move_to = position.to_i
    else
      self.insert_at(position.to_i)
    end
  end

  def insertion_point
    position
  end

  def add_steps(new_steps)
    @new_steps = new_steps
    self.procedure = true # FIXME,Manish,2012-02-09,It should instead fail if procedure is false.
  end

  def auto?
    !manual?
  end

  def startable?
    request.started? && (procedure? || ready? || locked? && execute_anytime?) && should_execute?
  end

  def completeable?
    (request.started? || request.problem? || request.hold?) and (in_process? or problem? or (startable? and GlobalSettings.one_click_completion?))
  end

  def show_complete_option?
    completeable? && !problem? && request.started?
  end

  def editable_by?(requesting_user, request, request_permissions = {})
    request ||= self.request

    if request
      !requesting_user.nil? && !request.already_started? && !complete? &&
          (request_permissions.fetch(:can_edit_step) { requesting_user.can?(:edit_step, request) } ||
           request_permissions.fetch(:request_available_for_user) { request.is_available_for_current_user? })
    else
      procedure? ? true : !complete?
    end
  end

  def resettable_by?(requesting_user)
    complete? && (request.hold? || request.planned?)
  end

  def owned_by?(requesting_user)
    return false if auto?
    belongs_to?(requesting_user, true)
  end

  def accessible_by?(requesting_user)
    owned_by?(requesting_user)
  end

  def commentable_by?(requesting_user)
    requesting_user.apps.map(&:id).include?(self.request.apps[0].id)
  end

  # To remove exception of "server_association_ids", modified below method
  # Removed ORPHANED which was added by Brady .But because of this installed_component are not updated properly.So used old code.
  # def ORPHANED_installed_component(force_reload = false
  def installed_component(force_reload = false)
    return unless request
    request.apps.each do |app|
      app.components.each do |comp|
        if comp.id == component_id
          @app = app
        end
      end
    end
    #@app = request.apps[0] unless @app
    if force_reload || @installed_component.nil?
      if @app
        app_component = @app.application_components.find_by_component_id(component_id) unless component_id.nil?
      end
      if app_component
        req_env = request.environment
        @installed_component = req_env.installed_components.find_by_application_component_id(app_component.id) if req_env
      end
    end
    @installed_component
  end

  # Trying to refactor the `installed_component` implementation as it does a lot of queries and hence is slow
  # Properties not loaded for steps with this implementation
  def installed_component_only(force_reload = false)
    return if self.component_id.nil? || !self.request.present?
    #@app = request.apps.joins(:components).where('components.id = ?', self.component_id).last

    if force_reload || @installed_component.nil?
      @installed_component = InstalledComponent.joins(application_environment: :environment, application_component: [:component]).
          where('environments.id = ? AND components.id = ?', self.environment.id, self.component_id).
          where('application_environments.app_id = ?', self.app_id).first
      # where('environments.id = ? AND components.id = ? AND apps.id = ?', self.environment.id, self.component_id, self.app_id).first
    end

    @installed_component
  end

  def get_installed_component(options = {})
    comp_id = options["component_id"] if options.keys.include?("component_id")
    environment_id = options["environment_id"] if options.keys.include?("environment_id")
    cur_app_id = get_app_id(options)
    environment_id ||= request.environment_id
    comp_id ||= component_id
    return if (comp_id.blank? || request.blank? || cur_app_id.blank?)
    #logger.info "SS__ IC_get: App: #{cur_app_id.to_s}, ReqAppID: #{request.app_ids[0]}, Env: #{environment_id}, Comp: #{comp_id.to_s}"
    InstalledComponent.without_finding_server_ids {
      InstalledComponent.find_by_app_comp_env(cur_app_id, comp_id, environment_id)
    }
  end

  def check_installed_component
    # called on step save
    return if request.nil?
    # return if (request.nil? || component.nil?)
    check_id = get_installed_component.try(:id)
    if check_id != installed_component_id
      self.installed_component_id = check_id
      self.app_id = get_app_id
      self.save(:validate => false)
    end
  end

  def bladelogic_password_available?
    if auto? && script.respond_to?(:step_authentication?) && script.step_authentication?
      !bladelogic_password.blank?
    else
      true
    end
  end

  def global_property_value_for(given_property, original_value_holder, mark_private = false)
    property = given_property.is_a?(Property) ? given_property : Property.find_by_id(given_property.to_i)
    resp = property.literal_value_for(original_value_holder)
    if mark_private
      resp = "-private-" if property.is_private
    end
    resp
  end

  def literal_property_value_for(given_property, original_value_holder, mark_private = false, p_request = nil)
    property = given_property.is_a?(Property) ? given_property : Property.find_by_id(given_property.to_i)
    value = (p_request || request).temporary_current_property_values.for(original_value_holder).find_by_property_id(property.id).try(:value)
    resp = value || property.literal_value_for(original_value_holder)
    if mark_private
      resp = (value.nil? ? "-private-" : " -private- ") if property.is_private
    end
    return resp
  rescue => e
    logger.error e.message
  end

  def render_literal_property_value_for(given_property, original_value_holder, mark_private)
    tmp = literal_property_value_for(given_property, original_value_holder)
    tmp = PRIVATE_PREFIX + tmp.to_s if mark_private && given_property.is_private
    tmp
  end

  def collect_package_properties(res, mark_private)
    application_package = request.find_application_package(package)
    application_package.properties.active.each do |prop|
      res[prop.name] = render_literal_property_value_for(prop, application_package, mark_private)
      res["#{prop.name}_encrypt"] = "encrypt" if prop.is_private
    end
  end

  def collect_package_instance_properties(res, mark_private)
    package_instance.properties.active.each do |prop|
      res[prop.name] = render_literal_property_value_for(prop, package_instance, mark_private)
      res["#{prop.name}_encrypt"] = "encrypt" if prop.is_private
    end
  end

  def current_property_values(mark_private = false)
    res = {}
    unless installed_component.nil?
      installed_component.properties.active.each do |prop|
        tmp = literal_property_value_for(prop, installed_component)
        tmp = PRIVATE_PREFIX + tmp.to_s if mark_private && prop.is_private
        res[prop.name] = tmp
        res["#{prop.name}_encrypt"] = "encrypt" if prop.is_private
      end
    end
    collect_package_properties(res, mark_private) unless package.nil?
    collect_package_instance_properties(res, mark_private) unless package_instance.nil?
    res
  end

  def property_values_summary
    res = {}
    unless installed_component.nil?
      installed_component.properties.active.each do |prop|
        tmp = literal_property_value_for(prop, installed_component, true)
        tmp2 = global_property_value_for(prop, installed_component, true)
        res[prop.name] = [tmp, tmp2]
      end
    end
    res
  end

  def property_values
    res = {}
    installed_component.properties.active.each do |prop|
      res[prop.name] = literal_property_value_for(prop, installed_component, true)
    end if installed_component.present?
    res
  end

  def property_values_summary_server(server = nil)
    res = {}
    unless installed_component.nil?
      if server.nil?
        servers.each do |server|
          res[server.name] = {}
          server.properties.each do |prop|
            tmp = literal_property_value_for(prop, server, true)
            tmp2 = global_property_value_for(prop, server, true)
            res[server.name][prop.name] = [tmp, tmp2]
          end
        end
        server_aspects.each do |server|
          res[server.full_name] = {}
          server.properties.each do |prop|
            tmp = literal_property_value_for(prop, server, true)
            tmp2 = global_property_value_for(prop, server, true)
            res[server.full_name][prop.name] = [tmp, tmp2]
          end
        end
      else
        props = {}
        server.properties.each do |prop|
          tmp = literal_property_value_for(prop, server, true)
          tmp2 = global_property_value_for(prop, server, true)
          props[prop.name] = [tmp, tmp2]
        end
        res[server.try(server.respond_to?(:full_name) ? :full_name : :name)] = props
      end
    end
    res
  end

  def update_property_values!(new_values)
    return unless new_values
    %w(installed_component server server_aspect application_package package_instance).each do |original_value_holder|
      new_values[original_value_holder].try(:each) do |original_value_holder_id, property_value_hash|
        original_value_holder_id = original_value_holder_id.to_i
        value_holder_object = original_value_holder.classify.constantize.find_by_id(original_value_holder_id)
        property_value_hash.each do |property_id, value|
          property_id, value = property_id.to_i, value.to_s
          current_value = literal_property_value_for(property_id, value_holder_object)
          if value != current_value # BJB
            archive_property_value(original_value_holder, original_value_holder_id, property_id)
            unless value == ""
              temp_value = request.temporary_current_property_values.for(original_value_holder, original_value_holder_id).find_or_initialize_by_property_id(property_id)
              temp_value.value = value
              temp_value.step_id = self.id
              temp_value.save
            end
            #logger.info "SS__ Setting temp prop(step): #{property_id.to_s} => #{value.to_s}"
          end
        end
      end
    end
  end

  def delete_step_references
    self.step_references.destroy_all
  end

  def create_step_references(reference_ids)
    owner_object_type = self.package_instance ? InstanceReference.to_s : Reference.to_s
    reference_ids.each do |reference_id|
      self.step_references << StepReference.create(step_id: self.id, reference_id: reference_id,
                                                   owner_object_id: (reference_id),
                                                   owner_object_type: owner_object_type)
    end
  end

  def get_reference_ids
    step_references.map(&:reference_id)
  end

  def update_references!
    if has_component? && related_object_type_changed?
      # remove all references if this step is using components
      self.reference_ids = []
    end

    unless self.reference_ids.nil?
      delete_step_references
      create_step_references(self.reference_ids)
    end
  end

  def targeted_servers
    (servers + server_aspects + server_groups.collect { |sg| sg.servers }.flatten).sort_by { |s| s.path_string }
  end

  def actual_associated_servers
    ((servers + server_aspects + server_groups.collect { |sg| sg.servers }.flatten) & installed_component.server_associations).sort_by { |s| s.path_string }
  end

  def all_servers
    return {} if installed_component.nil?
    available_servers = installed_component.server_associations
    selected_servers = targeted_servers
    return {} if available_servers.nil? & selected_servers.nil?
    alternate_servers = selected_servers.reject { |server| available_servers.include? server }
    target_servers = selected_servers - alternate_servers
    group_name = installed_component.get_server_group_name

    {selected_servers: {target_servers: {group_name => target_servers.as_json},
                        alternate_servers: alternate_servers.as_json},
     available_servers: {group_name => available_servers.as_json}}
  end

  def upload_file_for_script_arguments(file_arg_hash = {})
    return unless file_arg_hash.present?
    file_arg_hash.each do |k, v|
      step_script_argument = StepScriptArgument.find_by_step_id_and_script_argument_id(id, k)
      step_script_argument.update_attributes(v)
      if step_script_argument.uploads[0].present?
        step_script_argument.update_attribute(:value, [step_script_argument.uploads[0].filename])
      else
        step_script_argument.update_attribute(:value, [""])
      end
    end
  end

  def archive_property_value(original_value_holder, original_value_holder_id, property_id)
    cur_values = request.temporary_current_property_values.for(original_value_holder, original_value_holder_id).find_all_by_property_id(property_id)
    #logger.info "SS__ archive value: #{cur_values.inspect}, valHolder: #{original_value_holder_id}, propID: #{property_id}"
    unless cur_values.empty?
      cur_values.each do |cur_value|
        #logger.info "SS__ deleting temp value: #{cur_value.id}, for ic: #{cur_value.original_value_holder_id}"
        cur_value.deleted_at = Time.now
        cur_value.save
      end
    end
  end

  # FIXME, 2012-07-25, bbyrd, this method is not used, it should be removed.
  def set_property_values_from_script(results)
    reg_flag = /\$\$SS_Set_.+\}\$\$/
    reg = /\$\$SS_Set_Property.+\$\$/
    #msg = "SS__ Updating property values from script.\n"
    occurrences = results.scan(reg_flag)
    return if occurrences.empty?
    props = Hash.new
    set_props = Hash.new
    occurrences.each do |set_str|
      prop = set_str.gsub("$$SS_Set_Property{", "").gsub("}$$", "")
      keyval = prop.split("=>")
      props[keyval[0].strip] = keyval[1].strip
    end
    cur_props = current_property_values
    props.each do |k, v|
      if cur_props.has_key?(k)
        id = installed_component.properties.active.find_by_name(k).id
        msg += "SS__  Updating property #{k}(#{id.to_s}: change value from: #{cur_props[k]} to #{v.to_s}"
        set_props[id.to_s] = v.to_s # Add back as the id
      else
        msg += "\nSS__ Property not found: #{k}\n"
      end
    end
    #logger.info(msg)
    new_values = {"installed_component" => {installed_component.id.to_s => set_props}}
    update_property_values!(new_values)
  end

  def update_script_arguments_for_pack_response(results)
    reg_flag = /\$\$SS_Pack_.+\}\$\$/
    reg = /\$\$SS_Pack_Response.+\$\$/
    msg = "SS__ Updating step script argument values from script.\n"
    occurrences = results.scan(reg_flag)
    return if occurrences.empty?
    step_script_arg = {}
    occurrences.each do |set_str|
      arg_has = set_str.gsub("$$SS_Pack_Response{", "").gsub("}$$", "")
      if arg_has.include?("@@")
        keyval = arg_has.split("@@") # this mean response is a Hash and used for out-table output parameter
        step_script_arg[keyval[0].strip] = keyval[1].strip
      else
        keyval = arg_has.split("=>")
        step_script_arg[keyval[0].strip] = keyval[1].strip
      end
    end
    cur_script_args = self.script.arguments.map(&:argument)
    step_script_arg.each do |k, v|
      if cur_script_args.include?(k)
        argument = self.script.arguments.output_arguments.find_by_argument(k)
        argument_id = argument.try(:id) if argument
        step_script_arg = self.step_script_arguments.find_by_script_argument_id(argument_id) if argument_id
        if argument.argument_type == "out-external-single" && argument.external_resource.present?
          script_output = execute_script_for_out_param(argument, v)
          step_script_arg.update_attribute(:value, [script_output].flatten) if script_output
        elsif argument.argument_type == "out-external-multi" && argument.external_resource.present?
          script_output = execute_script_for_out_param(argument, v)
          step_script_arg.update_attribute(:value, [script_output].flatten) if script_output
        else
          step_script_arg.update_attribute(:value, [v].flatten)
        end
      else
        msg += "\nSS__ Argument not found: #{k}\n"
      end
    end
  end

  def execute_script_for_out_param(argument, selected_value)
    script_to_execute = Script.find_by_unique_identifier(argument.external_resource) rescue nil
    if script_to_execute
      script_params = script_to_execute.queue_run!(self, "false", execute_in_background=false)

      arg_file_name = script_params["SS_input_file"]
      input_file = FileInUTF.open(arg_file_name, "w")

      params_to_be_appended = Hash[script_params]

      if script_to_execute.arguments.present?
        self.script.arguments.each do |argument|
          argument_value = self.script_argument_property_value(argument, {})
          if argument_value.blank?
            values_from_properties = argument.values_from_properties(installed_component)
            argument_value = if ["in-external-multi-select", "in-user-multi-select", "in-server-multi-select"].include?(argument.argument_type)
                               values_from_properties
                             elsif ["in-external-single-select", "in-user-single-select", "in-server-single-select"].include?(argument.argument_type)
                               values_from_properties.first
                             else
                               values_from_properties.first
                             end
          end
          params_to_be_appended[argument.argument] = [argument_value].flatten.first
        end
      end
      input_content = Hash[params_to_be_appended.sort].to_yaml
      input_file.write(input_content)
      input_file.flush
      input_file.close
      automation_script_header = File.open("#{script_params["SS_script_file"]}").read
      external_script_output = eval("#{automation_script_header};execute(script_params,nil,0,0);")
      if argument.argument_type == "out-external-multi"
        selected_value = eval(selected_value) #This is just to get the array present inside an String
      end
      ApplicationController.helpers.options_for_select(external_script_output.try(:flatten_hashes), [selected_value].flatten)
    else
      nil
    end
  end


  def copy_script_parameters(destination_step)
    return unless auto?

    arg_hash = self.step_script_arguments.inject({}) do |hash, arg|
      hash.update arg.script_argument_id => self.script_argument_value(arg.script_argument_id)
    end

    destination_step.update_script_arguments! arg_hash
  end

  def turn_off!
    update_attribute(:should_execute, false)
  end

  def set_source_env_version(c_version) # c_version => component_version
    update_attribute(:component_version, c_version)
  end

  def version_name
    GlobalSettings.limit_versions? ? version_tag.try(:name) : component_version rescue nil
  end

  def current_component_version
    component_version.to_s.length < 1 ? (installed_component.nil? ? '' : installed_component.version) : component_version
  end

  # Checks if component version stored matches with original version of component
  def ic_version_if_changed
    return nil if do_not_check_for_version_change
    if step_not_modified
      begin
        # ae = application_environment
        ae = []
        request.apps.each do |app|
          ae << app.application_environments.find_by_environment_id(request.environment_id)
        end
        # ac = application_component
        ac = []
        ae.each do |app_env|
          ac << app_env.application_components.find_by_component_id(component_id)
        end
        ae.flatten!
        ac.flatten!
        # ic = installed_component
        ic = InstalledComponent.find_by_application_component_id_and_application_environment_id(ac.map(&:id), ae.map(&:id))
        ic.nil? ? nil : (ic.version.eql?(version_name) ? nil : ic.version)
      rescue
        nil
      end
    end
  end

  def do_not_check_for_version_change
    !request.created_from_template or component_id.nil? or version_name.nil? or !request.created?
  end

  def step_not_modified
    created_at.eql?(updated_at)
  end

  def selected_component_id
    component_id.nil? ? "" : component_id
  end

  def selected_package_template_id
    component_id.nil? ? package_template_id : ""
  end

  def create_package_instance_for_step_run
    res = {}
    if create_new_package_instance && package.present?
      res[:temp_new_package_instance_id] = create_package_instance.id
    end
    res
  end

  def create_package_instance
    create_params = {selected_reference_ids: step_references.map { |r| r.reference_id }}
    @package_instance = package.package_instances.build(create_params)
    PackageInstanceCreate.call(@package_instance)
    @package_instance.properties_with_values = current_property_values(true)
    @package_instance.save!
    @package_instance
  end

  def headers_for_step(in_params={})

    # BJB Returns a hash of values for automation scripts
    res = {
        # Moved process release and environment to request level
        #"process" => business_process_name,
        #"release" => release_name,
        # These should be deprecated and replaced with SS_ ones
        'application' => installed_component.try(:application_component).try(:app).try(:name) || '',
        'component' => component_name,
        'SS_application' => installed_component.try(:application_component).try(:app).try(:name) || '',
        #"environment" => environment_name,
        'request_id' => request.try(:number) || '',
        'step_id' => id,
        'step_number' => number,
        'step_name' => "#{name}".gsub("'", "''"),
        'step_owner' => owner_name,
        'step_task' => self.work_task.try(:name),
        'step_phase' => self.phase.try(:name),
        'step_runtime_phase' => self.runtime_phase.try(:name),
        'SS_environment' => request.try(:environment_name) || '',
        'step_description' => description.nil? ? '' : description.gsub("'", "''"),
        'step_user_id' => request.try(:last_activity_by) || '',
        'step_started_at' => "#{work_started_at}",
        'step_estimate' => estimate,
        # CHKME,Manish,2012-02-29,Conflicted item and can't figure out what's the good one.
        # "servers" => (servers.map(&:name) + server_aspects.map(&:full_name)).join(", ")
        'servers' => server_association_names.join(', '),
        'tickets_foreign_ids' => tickets.collect { |t| t.foreign_id }.join(', '),
        'ticket_ids' => tickets.collect { |t| t.id }.join(', ')
    }

    new_package_instance_created = in_params[:temp_new_package_instance_id].present?

    res['step_object_type'] = related_object_type unless related_object_type.nil?
    res['step_create_new_package_instance'] = !!create_new_package_instance
    res['step_latest_package_instance'] = !!latest_package_instance

    add_headers_for_package res
    add_headers_for_package_instance res, package_instance
    add_latest_package_instance res if latest_package_instance
    if new_package_instance_created
      add_headers_for_package_instance(res, PackageInstance.find(in_params[:temp_new_package_instance_id]))
    end
    add_package_details res unless new_package_instance_created || latest_package_instance || package_instance.present?
    in_params.delete(:temp_new_package_instance_id)

    res['step_ref_ids'] = step_references.map { |r| r.reference_id }.join ','
    res['step_ref_names'] = step_references.map { |r| r.owner_object.name }.join ','

    if installed_component.nil?
      res['SS_component'] = ''
      res['SS_component_version'] = ''
      res['SS_component_template_0'] = ''
    else
      res['component_version'] = current_component_version
      res['component'] = component_name
      res['SS_component'] = component_name
      res['SS_component_version'] = current_component_version
      installed_component.application_component.component_templates.each_with_index do |ct, idx|
        res["SS_component_template_#{idx.to_s}"] = ct.name
      end
    end
    #BJB Add access to file attachments
    self.uploads.each_with_index do |upload, idx|
      res['step_attachment_' + idx.to_s] = upload.attachment.file.file
    end
    if version_tag.nil?
      res['step_version'] = component_version
    else
      res['step_version'] = version_tag.name
      res['step_version_artifact_url'] = version_tag.artifact_url
    end
    res.merge!(current_property_values(true))
  end

  def add_package_details(res)
    step_references.each do |step_reference|
      reference = step_reference.owner_object
      res["step_ref_#{reference.name}_uri"] = reference.uri
      res["step_ref_#{reference.name}_server"] = reference.server.name
      res["step_ref_#{reference.name}_method"] = reference.resource_method
      reference.property_values.each do |property_value|
        res["step_ref_#{reference.name}_property_#{property_value.name}"] = property_value.value
      end
    end
  end

  def add_latest_package_instance(res)
    package_instance = package.latest_package_instance
    if package_instance
      add_headers_for_package_instance(res, package_instance)
      step_references.each do |step_reference|
        reference = step_reference.owner_object
        instance_reference = package_instance.find_instance_reference_for_reference reference
        add_instance_reference_details(res, instance_reference) if instance_reference.present?
      end
    end
  end

  def add_instance_reference_details(res, instance_reference)
    res["step_ref_#{instance_reference.name}_uri"] = instance_reference.uri
    res["step_ref_#{instance_reference.name}_server"] = instance_reference.server.name
    res["step_ref_#{instance_reference.name}_method"] = instance_reference.resource_method
    instance_reference.property_values.each do |property_value|
      res["step_ref_#{instance_reference.name}_property_#{property_value.name}"] = property_value.value
    end
  end

  def add_headers_for_package_instance(res, package_instance)
    unless package_instance.nil?
      res["step_package_instance_id"] = package_instance.id
      res["step_package_instance_name"] = package_instance.name
      add_package_instance_details(res, package_instance)
    end
  end

  def add_headers_for_package(res)
    unless package.nil?
      res["step_package_id"] = package.id
      res["step_package_name"] = package.name
    end
  end

  def add_package_instance_details(res, package_instance)
    package_instance.property_values.each do |property_value|
      res["step_instance_property_#{property_value.name}"] = property_value.value
    end
    step_references.each do |step_reference|
      reference = step_reference.owner_object
      res["step_ref_#{reference.name}_uri"] = reference.uri
      res["step_ref_#{reference.name}_server"] = reference.server.name
      res["step_ref_#{reference.name}_method"] = reference.resource_method
      reference.property_values.each do |property_value|
        res["step_ref_#{reference.name}_property_#{property_value.name}"] = property_value.value
      end
    end
  end

  def exact_position
    procedure? ? "#{parent.id}:#{position}" : position
  end

  def to_label(to_state, state_label=nil)
    "Step #{number}: #{work_task && work_task.name} #{component && component.name}, #{state_label.blank? ? to_state.to_s.humanize : state_label}"
  end

  def set_owner_attributes
    if manual?
      connection.execute("UPDATE steps SET script_id = NULL, script_type = NULL WHERE id = #{id} AND manual = #{RPMTRUE}")
    else
      #connection.execute("UPDATE steps SET owner_id = NULL, owner_type = NULL WHERE id = #{id} AND manual = 0")
    end
  end

  def update_consistency_check(params)
    if params["manual"] == "true"
      script = nil
      script_type = nil
      save
    end
  end

  def self.update_position_column(request)
    request_steps = request.steps.sort_by_parent_position
    step_number = 0
    parent_step_number = 0
    parent_step_id=0
    request_steps.each do |step|
      if step.parent_id?
        unless parent_step_id == step.parent_id
          parent_step_number = 0
          parent_step_id = step.parent_id
        end
        parent_step_number += 1
        step.update_attribute('position', parent_step_number)
      else
        step_number += 1
        step.update_attribute('position', step_number)
        parent_step_number = 0
      end
    end if request_steps.present?
  end

  def self.without_checking_installed_component
    Step.skip_callback(:save, :before, :check_installed_component)
    result = yield
    Step.set_callback(:save, :before, :check_installed_component)

    result
  end

  def available_versions
    ans = installed_component.version_tags.unarchived.order("LOWER(name) asc") unless installed_component.nil?
    ans ||= []
  end

  def has_ticket(ticket_id)
    self.tickets.map(&:id).include?(ticket_id)
  end

  ### public work methods
  # FIXME: use the state machine public calls and not these methods
  # do to the work of freezing and unfreezing


  def freeze_step
    freeze_owner
    freeze_component
    freeze_automation_script
    freeze_bladelogic_script
    freeze_work_task
  end

  def unfreeze_step!
    unfreeze_step
    save!
  end


  def unfreeze_step
    unfreeze_owner
    unfreeze_component
    unfreeze_automation_script
    unfreeze_bladelogic_script
    unfreeze_work_task
  end

  def unblock!
    if work_started_at?
      unblock_in_process!
    else
      unblock_ready!
    end
  end

  def prepare_for_work!
    if %w(problem hold).include?(request.aasm_state)
      parent.lock! if parent && parent.in_process?
      return
    end

    ready_for_work!
    auto_start

    if procedure? && !in_process?
      lets_start!

      prepare_steps_for_execution
    end
  end

  def safe_ready_for_work!
    ActiveRecord::Base.connection_pool.with_connection do
      # fetch current step aasm_state from DB
      # reason: some weird ghost defect where 1 of ~1000 automation steps hangs instead of
      # transitioning to `ready` state
      self.reload
      ready = self.locked? && ready_for_work! # avoid invalid transitions when "restarting" a request

      logger.error "Error: Step##{self.id} cannot transition to `ready` from `#{self.aasm_state}`. Step => #{self.inspect}" unless ready

      logger.error "Error: #{self.errors.full_messages}" if self.errors.any?

      ready
    end
  end

  def lets_start!
    begin
      if start!
        run_script
        update_attribute :work_started_at, Time.now
        true
      else
        false
      end
    rescue Exception => exc
      notes.create(:content => exc.message, :user_id => request.user_id)
      problem!
    end
  end

  # TODO: Needs performance fix
  def all_done!
    unless complete?
      self.work_started_at = Time.now unless work_started_at?
      self.work_finished_at = Time.now
      done!
      #update_properties - Now done at request level
      if component_id && own_version?
        update_installed_component_version
      end
    end

    containing_object = parent || request
    containing_object.state_changer = state_changer
    containing_object.prepare_steps_for_execution(self)

    #    unless version.blank?
    #      installed_component.update_attribute(:version, version) if installed_component
    #    end
    the_steps = containing_object.is_a?(Request) ? containing_object.steps.top_level.reload : containing_object.steps.reload

    if the_steps.all? { |step| step.complete_or_not_executable? }

      if containing_object.respond_to?(:finish!)
        containing_object.finish! if containing_object.started?
      else
        containing_object.all_done!
      end

    end


  end

  def complete_step!
    freeze_step unless procedure
    save!
  end

  def mailing_list
    recipients = []
    recipients << self.group_and_members_email(self.request.notify_group_only)
    recipients << request.step_owner_emails(request.executable_steps) if request.notify_on_step_step_owners
    recipients << [self.request.owner.email, self.request.requestor.email] if self.request.notify_on_step_requestor_owner
    if self.request.notify_on_step_participiant
      recipients << self.request.additional_email_addresses
      recipients << self.request.emails_group(self.request.notify_group_only)
      recipients << self.request.email_recipients_for(:user).map(&:email)
    end
    recipients.flatten.uniq.delete_if { |e| e.blank? }
  end

  def group_and_members_email(group_only)
    emails = []
    if self.owner.is_a?(Group)
      if group_only
        self.owner.email.blank? ? self.owner.resources.map { |user| emails << user.email } : emails << self.owner.email
      else
        self.owner.resources.map { |user| emails << user.email }
        emails << self.owner.email
      end
    else
      emails << self.owner.email
    end
  end

  def to_json(options = {})
    options[:except] ||= [:frozen_owner, :frozen_automation_script, :frozen_bladelogic_script, :frozen_component, :frozen_work_task]
    super(options)
  end

  def to_xml(options = {})
    options[:except] ||= [:frozen_owner, :frozen_automation_script, :frozen_bladelogic_script, :frozen_component, :frozen_work_task]
    super(options)
  end

  def only_procedures_from_in_process?
    ready? || (procedure? && in_process?) || problem?
    # true
  end

  def design_state?
    # TODO: CHECK REQUIREMENTS
    new_record? || DESIGN_STATES.include?(aasm_state)
  end

  def allow_mail_delivery?
    !procedure? && !suppress_notification
  end

  def enabled_editing?(user)
    # :TODO here was check on executor role, may be we should add new permissions for this check
    if request.nil?
      user.can?(:edit_step, Request.new)
    else
      user.can?(:edit_step, request) && editable?
    end
  end

  def parent_object
    return floating_procedure if floating_procedure.present?
    return request
  end

  def editable?
    REQUEST_STATES_TO_EDIT_STEP.include?(parent_object.aasm.current_state) && locked?
  end

  def view_object
    @view_object ||= StepView.new(self)
  end

  def script_arguments
    (script || Script.new).arguments
  end

  def archived_procedure?
    floating_procedure.present? && floating_procedure.archived?
  end

  private

  def get_tickets_information
    if plan && !tickets.blank?
      buffer = "---------------------------------------- Tickets Summary -------------------------------------------\n"
      tickets.each { |t| buffer = buffer + t.get_printable_data }
      buffer = buffer + "----------------------------------------------------------------------------------------------------\n"
      buffer
    else
      ''
    end
  end

  def get_app_id(options = {})
    #logger.info "SS__ GetAppID: options: #{options.inspect}"
    result = app_id
    if options.keys.include?("app_ids")
      new_ids = options["app_ids"].is_a?(String) ? options["app_ids"].split(",") : new_ids
      #logger.info "SS__ GetAppID: usingkeys: #{new_ids.inspect}"
      result = new_ids[0]
      unless component_id.nil?
        request.apps.each do |cur_app|
          # Now check if installed component environments include the passed env
          if cur_app.component_ids.include?(component_id)
            ic = InstalledComponent.find_by_app_comp_env(cur_app.id, component_id, options["environment_id"])
            #  Note: last app to contain the component wins!
            #logger.info "SS__ GetAppID: IC test comp: #{component_id}, ic: #{ic.inspect}"
            result = cur_app.id if ic
          end
        end
      end
    else
      result = request.app_ids[0] unless request.app_ids.include?(app_id)
    end
    result
  end

  def stitch_package_template_id
    return if temp_component_id.nil?
    if temp_component_id.gsub(/package_template_\d+/, '') == ''
      write_attribute(:package_template_id, temp_component_id.gsub(/package_template_/, ''))
      write_attribute(:component_id, nil)
    else
      write_attribute(:package_template_id, nil)
      write_attribute(:package_template_properties, nil)
    end
  end

  def acts_as_list_scope
    if procedure_id?
      "procedure_id = #{procedure_id}"
    elsif parent_id?
      "parent_id = #{parent_id} AND request_id = #{request_id}"
    else
      "parent_id IS NULL AND request_id = #{request_id}"
    end
  end

  def auto_start
    return unless auto?

    unless script.respond_to?(:step_authentication?) && script.step_authentication?
      lets_start!
    end
  end

  def resolve_run_script
    run_script(true)
  end

  def run_script(resolving = false)

    # Add tickets information to the notes
    unless resolving
      notes.create(content: get_tickets_information, user_id: request.last_activity_by)
    end

    return unless auto?
    #return if being_resolved? && !rerun_script
    if resolving && (rerun_script == 'false')
      return
    end

    clear_output_step_script_arguments(self)
    update_script_arguments!

    begin
      #logger.debug "SS__ Queuing: #{position}) #{id.to_s}-#{name}"
      script.queue_run!(self)
      #logger.debug "SS__ Queue-finish: #{position}) #{id.to_s}-#{name}, time:#{Time.now - start_time}"
    rescue => e
      notes.create(:content => "Error: #{e.message}\n#{e.backtrace}", :user_id => request.last_activity_by)
      Rails.logger.error(e.message)
      Rails.logger.error(e.message.inspect)
    end

  end

  def reformat_dates_to_us_format
    @complete_by_date = reformat_date(@complete_by_date) unless @complete_by_date.blank?
    @start_by_date = reformat_date(@start_by_date) unless @start_by_date.blank?
  end

  def has_exactly_one_parent
    self.errors[:base] << "must belong to either a request or procedure" if request && floating_procedure
  end

  def move_into_position
    insert_at(@move_to) if @move_to
  end

  def add_new_steps
    if @new_steps
      @new_steps.each do |step|
        new_step = steps.create! step.attributes.merge('procedure_id' => nil, 'request_id' => request_id).delete_if { |key, _| key == 'id' }
        step.copy_script_parameters new_step
        new_step.update_attributes(:installed_component_id => new_step.get_installed_component.try(:id))
      end
      @new_steps = nil
    end
  end

  def generate_estimate
    if @estimate_hours.present? or @estimate_minutes.present?
      @estimate_minutes = 0 unless (0..999).include?(@estimate_minutes)
      final_estimate = @estimate_hours * 60 + @estimate_minutes
      self.estimate = final_estimate
    else
      self.estimate = estimate
    end
  end


  def update_installed_component_version
    return unless installed_component

    installed_component.update_attribute(:version, version_name) unless version_name.blank?
  end

  def update_request_status
    if problem?
      unless request.problem?
        request.problem_encountered!
        update_activity_logs
      end
    else
      if request.steps.problem.empty?
        request.resolve!
        update_activity_logs
      end
    end
  end

  # This method is used to update the activity logs for the request when step is going to `Problem` state
  def update_activity_logs
    request_number = request.number
    req_link = "<a href = 'requests/#{request_number}'>#{request_number}</a>"
    app = request.app_name.size > 1 ? "Applications" : "Application"
    # Log activity is not supported in Rails3
    #User.current_user.log_activity(:context => "#{req_link} has been #{request.aasm_state} for #{app} #{request.app_name.to_sentence}") do
    #end
  end

  def audit_log
    ActivityLog.log_event(self.request, User.current_user, "deleted step #{self.name}")
  end

  def reorder_if_parallel_steps
    if different_level_from_previous
      steps_ahead = Step.next_step request_id, id
      if !steps_ahead.blank? and !steps_ahead.first.different_level_from_previous
        steps_ahead.first.update_attribute("different_level_from_previous", true)
      end
    end
  end

  def remove_execution_conditions
    if phase_id_was != phase_id
      StepExecutionCondition.delete(
          referenced_conditions.joins(:runtime_phase)
          .where("step_execution_conditions.condition_type='runtime_phase' AND runtime_phases.phase_id != ?", phase_id)
      )
    end
  end

  def clear_output_step_script_arguments(step)
    ### BladeLogicScript don`t have output_params
    unless step.script.class == BladelogicScript
      step.step_script_arguments.where("script_argument_id in (?)", step.script.arguments.output_arguments.pluck(:id)).update_all(:value => '')
    end
  end

  def validate_aasm_event
    self.executable_event ||= AasmEvent::StepExecuteEvent.new(self)
    self.executable_event.validate_aasm_event
  end

  # if an aasm_event was passed through parameters on an update or create with no errors, then run it
  def run_aasm_event
    # make sure the is a command waiting to run and there are no errors on it.
    self.executable_event.run_aasm_event if self.errors[:aasm_event].blank?
  end
end
