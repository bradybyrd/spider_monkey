################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################
require 'sortable_model'
require 'permission_scope'
require 'set'

class RequestTemplate < ActiveRecord::Base

  include ArchivableModelHelpers
  include FilterExt
  include ObjectState
  include PermissionScope

  attr_accessible :name, :recur_time, :team_id, :parent_id, :request_id_to_clone, :aasm_state, :created_by
  attr_accessor :existing_request_id, :request_id_to_clone

  # as we unify access from various controllers, rest, and automation,
  # we want to have the model take care of creation routines as much as possible

  # when a request template is created, it has a special relationship to the
  # request used as its basis
  before_validation :set_request_to_clone, on: :create

  # without wanting to refactor the original class methods, which should have been validation
  # and after save hooks, I am just calling the class method after create for REST
  # calls and hoping for the best
  after_commit :copy_from_request_for_rest, on: :create

  paginate_alphabetically by: :name

  EXCLUDE_FROM_REQUEST = [:aasm_state, :completed_at, :started_at, :request_template_id, :scheduled_at,
                          :created_at, :updated_at, :activity_id, :frozen_app, :frozen_environment,
                          :frozen_business_process, :frozen_deployment_coordinator, :frozen_release,
                          :frozen_requestor, :plan_member_id, :parent_request_id,
                          :deployment_window_event_id, :auto_start]

  EXCLUDE_FROM_STEP = [:aasm_state, :work_started_at, :work_finished_at, :created_at, :updated_at,
                       :frozen_owner, :frozen_component, :frozen_automation_script, :frozen_bladelogic_script, :frozen_work_task]

  has_one :request, dependent: :destroy
  has_many :apps, through: :request
  has_many :apps_requests, through: :request
  has_one :environment, through: :request

  # For sorting
  belongs_to :parent_template, foreign_key: 'parent_id', class_name: 'RequestTemplate'

  has_many :plan_stages_request_templates
  has_many :plan_stages, through: :plan_stages_request_templates

  validates :name, presence: true
  validates :request, presence: true
  validate :validate_name

  delegate :attributes, to: :request, prefix: true

  sortable_model

  # initialize AASM state machine for object status
  init_state_machine

  can_sort_by :name, lambda { |asc, _| order("lower(request_templates.name) #{asc}") }
  can_sort_by :app, lambda { |asc, with_requests|
    if with_requests.blank?
      joins('LEFT JOIN requests ON request_templates.id = requests.request_template_id ' +
                'INNER JOIN apps_requests ON apps_requests.request_id = requests.id ' +
                'INNER JOIN apps ON apps_requests.app_id = apps.id').order("lower(apps.name) #{asc}")
    else
      joins('INNER JOIN apps ON apps_requests.app_id = apps.id').order("lower(apps.name) #{asc}")
    end }
  can_sort_by :environment, lambda { |asc, with_requests|
    if with_requests.blank?
      includes(:environment).order("lower(environments.name) #{asc}")
    else
      joins('LEFT JOIN environments ON requests.environment_id = environments.id').order("lower(environments.name) #{asc}")
    end
  }

  scope :sorted, lambda { order('lower(request_templates.name)') }
  scope :by_app_id, lambda { |app_ids| joins(:apps_requests).where(apps_requests: { app_id: app_ids }) }
  scope :by_user_apps, lambda { |user|
    assigned_app_ids = user.assigned_apps.select('assigned_apps.app_id').to_sql
    joins(:apps_requests).where("apps_requests.app_id in(#{assigned_app_ids})")
  }

  def self.templates_for(user, app_id=nil)
    result = user.admin? ? scoped : by_user_apps(user)
    if app_id.present?
      result.by_app_id(app_id)
    else
      result
    end
  end

  scope :by_environment_id, lambda { |environment_id|
    includes(:request).where('requests.environment_id = ?', environment_id)
  }

  def self.recurring_at(recur_time)
    recur_time = Time.parse(recur_time) if recur_time.kind_of?(String)
    lower_bound = recur_time.beginning_of_quarter_hour.seconds_since_midnight.to_i
    upper_bound = lower_bound + 15.minutes - 1

    where('request_templates.recur_time BETWEEN ? AND ?', lower_bound, upper_bound)
  end

  scope :name_order, order('request_templates.name ASC')

  scope :template_siblings, lambda { |request_parent| where(parent_id: request_parent) }

  scope :filter_by_name, lambda { |filter_value| where('LOWER(request_templates.name) like ?', filter_value.downcase) }

  # may be filtered through REST
  is_filtered cumulative: [:name],
              cumulative_by: {parent_id: :template_siblings,
                              environment_id: :by_environment_id,
                              app_id: :by_app_id,
                              recur_time: :recurring_at},
              boolean_flags: {default: :unarchived, opposite: :archived}


  def application_environments
    if request.present?
      request.application_environments
    else
      ApplicationEnvironment.all
    end
  end

  def automation_scripts_for_export
    request.steps.map(&:script).as_json(
        only: [:name, :description, :aasm_state, :content, :automation_type, :automation_category],
        include: {project_server: {only: project_server_safe_attributes}}
    )
  end

  def can_be_archived?
    count_of_plan_templates_through_request_templates == 0
  end

  def count_of_plan_templates_through_request_templates
    plan_stages.select { |ls| !ls.plan_template.archived? if ls.plan_template.present? }.count
  end

  class << self

    def template_variants(request)
      id = if request.request_template.parent_id.nil?
             request.request_template_id
           else
             request.request_template.parent_id
           end
      RequestTemplate.template_siblings(id)
    end

  end

  # TODO - Request template name can be same for different applications.
  # Need something like this
  # validates_uniqueness_of :name, :scope => :app_id
  def validate_name
    return if name.blank?
    rt = if new_record?
           self.class.where('LOWER(name) LIKE ?', name.downcase).limit(1).first
         else
           self.class.where('id != ? AND LOWER(name) LIKE ?', id, name.downcase).limit(1).first
         end

    unless rt.blank?
      rt_link = " by request template <a href='#{ContextRoot::context_root}/requests/#{rt.request.number}' target='_blank'><b>#{rt.name}</b></a>"
      self.errors[:base] << "Name has already been taken#{rt_link}"
    end

  end

  def self.initialize_from_request(request_for_template, new_attributes = nil)
    new_template = RequestTemplate.new(new_attributes)
    new_template.request = request_for_template.dup(except: EXCLUDE_FROM_REQUEST)
    request_for_template.apps.each do |app|
      new_template.request.apps.push(app)
    end
    new_template.clone_user_group_emails(request_for_template)
    new_template
  end

  def clone_user_group_emails(request_for_template)
    request_for_template.email_recipients.each do |recipient|
      self.request.email_recipients << recipient.dup
    end
  end

  def self.copy_from_request(original_request, new_template)

    execution_condition_hash = {}

    original_request.uploads.each do |upload|
      new_template.request.uploads << upload.deep_copy
    end

    original_request.steps.top_level.each do |step|
      new_step = step.dup
      new_step.ignore_current_script_arguments = true
      step.uploads.each do |upload|
        new_step.uploads << upload.deep_copy
      end

      new_template.request.steps << new_step
      updater = {}
      EXCLUDE_FROM_STEP.each do |fld|
        updater[fld] = nil
      end
      updater[:aasm_state] = 'locked'
      updater[:position] = step.position
      updater[:request_id] = new_template.request.id
      new_step.update_attributes(updater)
      step.copy_execution_condition_to(new_step)
      step.copy_script_arguments_to(new_step, {'clone_request_id' => original_request.id}) #, new_template.request)
      if new_template.request.has_same_env_as?(original_request, original_request.environment_id)
        new_step.servers << step.servers unless step.servers.blank?
      end

      step.steps.each do |proc_step|
        new_proc_step = proc_step.dup(except: EXCLUDE_FROM_STEP)
        new_proc_step.ignore_current_script_arguments = true
        new_proc_step.request = new_template.request

        proc_step.uploads.each do |upload|
          new_proc_step.uploads << upload.deep_copy
        end
        new_step.steps << new_proc_step
        proc_step.copy_script_arguments_to(new_proc_step, {'clone_request_id' => original_request.id})
        if new_template.request.has_same_env_as?(original_request, original_request.environment_id)
          new_proc_step.servers << proc_step.servers unless proc_step.servers.blank?
        end
      end
      execution_condition_hash[step.number] = step.execution_condition.try(:referenced_step).try(:number) if step.execution_condition
      new_template.save
      new_template.request.save
    end
    Step.update_execution_condition(execution_condition_hash, new_template.request)
  end

  def recur_time=(new_time)
    new_time = Time.parse(new_time) if new_time.kind_of?(String)
    if new_time
      self[:recur_time] = new_time.seconds_since_midnight.to_i
    else
      self[:recur_time] = nil
    end
  end

  def recur_time
    self[:recur_time].seconds.since(Time.parse('0:00')) if recur_time?
  end

  def instantiate_request(form_params = {})
    new_request = nil
    form_params[:request] = {} unless form_params[:request]
    execute_now = form_params[:request][:execute_now]

    transaction do
      begin
        form_params[:request][:should_time_stitch] = true
        form_params[:request][:rescheduled] = false

        @existing_request_id = form_params[:request][:id] if form_params[:request][:id]

        user = nil
        if form_params[:request][:owner_id].blank?
          user = User.current_user
          form_params[:request][:owner_id] = user.id
        else
          # FIXME: We do not handle a missing or malformed owner id -- this is a quick fix
          user = User.find_by_id(form_params[:request][:owner_id]) || User.current_user
          form_params[:request][:owner_id] = user.id if user.id != form_params[:request][:owner_id].to_i
        end

        data = nil
        if form_params[:request][:data]
          data = form_params[:request].delete(:data)
        end

        new_request = create_request_for(user, form_params)
        return new_request unless new_request.valid?

        form_params[:request].delete_if { |k, v| v.blank? || k.eql?('app_ids') || k.include?('plan') || k.eql?('execute_now') }
        unless form_params[:request][:package_content_ids]
          new_request.attributes = form_params[:request].merge!({package_content_ids: form_params[:package_content_ids]})
        end

        self.request.email_recipients.each do |recipient|
          new_request.email_recipients << recipient.dup
        end

        new_request.save
        new_request.turn_off_steps # Turn OFF steps whose components are not selected
        new_request.set_commit_version_of_steps
        new_request.reload

        if data
          save_request_data(new_request, data)
        end

      rescue => ex
        Rails.logger.error "Error when creating request from request template. #{ex.backtrace}"
        raise ActiveRecord::Rollback
      end
    end

    if new_request && new_request.valid? && execute_now && execute_now.to_bool == true
      new_request.plan_it!
      new_request.start_request!
    end

    new_request
  end

  def save_request_data(request, data)
    # Note: In case there is any exception encountered over here,
    # it gets caught in the calling controller
    output_dir = AutomationCommon.get_request_dir(request)
    file_name = "#{output_dir}/request_data.json"
    data_file = File.new(file_name, 'w+')
    data_file.print(data.to_json)
    data_file.close
  end

  def handle_step_versions(source, step, include_versions, new_ic_id)
    if new_ic_id.blank? || !include_versions
      # Case 1: No matching installed component found, clear versions
      # Case 2: We were not asked to retain versions.
      step.version_tag_id = nil
      step.component_version = nil
    else
      if GlobalSettings.limit_versions? && source.version_tag_id
        source_v = VersionTag.unarchived.find(source.version_tag_id) rescue nil
        target_v = VersionTag.unarchived.find_by_name_and_installed_component_id(source_v.name, new_ic_id) rescue nil if source_v
        if target_v
          # Case 3: Structured versions and we found matching version tag
          #   Case 3a: Same installed component
          #   Case 3b: Different installed component in same app
          #   Case 3c: Different installed component in different app
          step.version_tag_id = target_v.id
          step.component_version = target_v.name
        else
          # Case 4: Matching version not found. Clear if not found
          step.version_tag_id = nil
          step.component_version = nil
        end
      else
        # Case 5: Unstructured versions - At least retain all or retain versions was set.
        #         So, component_version should be copied as it is
        # Case 6: Structured versions, but no version associated with step - Both version_tag_id and component version fields
        #         will be blank, and copied as they are
      end
    end
  end

  def create_request_for(user, form_params = {})
    validation_skippers = form_params.delete(:validation_skippers) || []
    req = self.try(:request, include: [:apps, :uploads])
    # trap invalid environment id which can throw off later tests
    form_params = form_params.deep_symbolize_keys
    if form_params[:request] && form_params[:request][:environment_id] && form_params[:request][:environment_id].respond_to?(:to_i) && form_params[:request][:environment_id].to_i > 0
      new_environment_id = form_params[:request][:environment_id].to_i
    else
      new_environment_id = req.try(:environment_id)
    end

    exclude_from_request = EXCLUDE_FROM_REQUEST
    exclude_from_step = EXCLUDE_FROM_STEP

    form_params[:include] = {users: true} unless form_params.has_key?(:include)
    include_options = form_params[:include] || {}
    if include_options[:all]
      # we do not need to clone script arguments, because we have a cloning routine that does this a little more carefully below
      step_associations = [:notes]
    else
      exclude_from_request.push(:target_completion_at, :notify_on_request_start, :plan_member_id)
      exclude_from_step.push(:complete_by)
      step_associations = nil
    end

    if existing_request_id.nil_or_empty? # This is added to make apply_template to existing request feature work with same code
      # uses new deep_cloneable syntax from gem https://github.com/moiristo/deep_cloneable
      # TODO: use deep clone association cloning instead of ad hoc code that follows for associations
      new_request = req.dup(except: exclude_from_request)
      if form_params[:request_template_id]
        new_request.created_from_template = true
        new_request.origin_request_template_id = form_params[:request_template_id]
      end
      new_request.state_changer = user
      new_request.environment_id = new_environment_id

      if form_params[:request] && form_params[:request][:app_id]
        new_request.apps.push(App.find(form_params[:request][:app_id])) rescue nil
      else
        req.apps.each do |app|
          new_request.apps.push(app)
        end
      end
      if form_params[:request][:plan_member_attributes].present? &&
          form_params[:request][:plan_member_attributes][:plan_id].present? &&
          form_params[:request][:plan_member_attributes][:plan_stage_id].present?
        new_request.build_plan_member(plan_id: form_params[:request][:plan_member_attributes][:plan_id], plan_stage_id: form_params[:request][:plan_member_attributes][:plan_stage_id])
      end
      [:should_time_stitch, :deployment_window_event_id, :estimate, :scheduled_at_date, :scheduled_at_hour,
       :scheduled_at_minute, :scheduled_at_meridian].each do |field|
        new_request.send("#{field}=", form_params[:request][field]) if form_params[:request][field].present?
      end
      validation_skippers.each do |validation_skipper|
        begin
          new_request.send("#{validation_skipper.to_s}=", true)
        rescue
          logger.error I18n.t(:unable_set_request_validation_skipper, skipper: validation_skipper)
        end
      end
      if form_params[:request][:from_run]
        # TODO: Needs refactoring to do proper request creation for run w/o route gate constraints
        new_request.valid?
        new_request.save(validate: false)
      else
        return new_request unless new_request.save
      end
    else
      new_request = Request.find(existing_request_id)
    end
    new_request.copied_from_template = true

    # function to link plan only if selected on new request form
    # passed_lc_member = form_params[:request][:plan_member_attributes] if form_params[:request]
    # unless passed_lc_member.blank? || passed_lc_member[:plan_id].blank?
    #   clone_or_update_plan_member(new_request, passed_lc_member)
    # end

    req.uploads.each do |upload|
      new_request.uploads << upload.deep_copy
    end

    request_params = {new_environment_id: new_environment_id,
                      include_options: include_options,
                      step_associations: step_associations,
                      exclude_from_step: exclude_from_step}

    req.clone_steps(new_request, request_params)

    new_request.update_column(:deployment_coordinator_id, user.id) # user.owning_requests << new_request
    new_request
  end

  def has_all_components(component_ids)
    return true if component_ids.nil_or_empty?
    acs = ApplicationComponent.find(:all, :conditions => {:id => component_ids.collect { |i| i.to_i }}) # acs => application_components
    concerned_components = []
    acs.each { |ac| concerned_components << ac.component.id }
    concerned_components.to_set.subset?(request.steps.map(&:component_id).compact.uniq.to_set)
  end

  def created_string
    creator = created_by.nil? ? 'unknown' : User.find_by_id(created_by).try(:name)
    "#{creator} on #{created_at.try(:default_format_date_time)}"
  end

  protected

  # a routine that was formerly handled in the request template controller
  # create action, but has moved to a call-back chain for transactional support and rest
  # compatibility
  def set_request_to_clone
    success = false
    if request_id_to_clone.present?
      @request_to_clone = Request.find_by_id(request_id_to_clone)
      if @request_to_clone
        self.request = @request_to_clone.dup(except: EXCLUDE_FROM_REQUEST)
        @request_to_clone.apps.each do |app|
          self.request.apps.push(app)
        end
        self.request_id_to_clone = nil
        success = true
      else
        self.errors.add(:request_id_to_clone, ' could not be matched with a valid request.')
      end
    else
      success = true
    end
    success
  end

  def copy_from_request_for_rest

    # the variable @request_to_clone will only be set by rest calls that needed to validate
    # the id passed through request_id_to_clone.  Ideally all controllers would use the same
    # attributes, validations, and callbacks to accomplish this work but this was not in
    # scope for this effort.
    unless @request_to_clone.blank?
      # tuck a copy in a local variable
      cached_request = @request_to_clone

      # get rid of the instance variable so this hook only runs once
      @request_to_clone = nil

      RequestTemplate.copy_from_request(cached_request, self)

    end
    true
  end

  private

  def project_server_safe_attributes
    [:server_name_id, :details, :ip, :name, :password, :port, :server_url, :username]
  end
end
