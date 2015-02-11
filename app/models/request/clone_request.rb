class Request < ActiveRecord::Base

  EXCLUDE_FROM_STEP = [:aasm_state, :work_started_at, :work_finished_at, :created_at, :updated_at,
                       :frozen_owner, :frozen_component, :frozen_automation_script, :frozen_bladelogic_script, :frozen_work_task]

  EXCLUDE_FROM_REQUEST = [:aasm_state, :completed_at, :started_at, :request_template_id,
                          :created_at, :updated_at, :activity_id, :frozen_app, :frozen_environment,
                          :frozen_business_process, :frozen_deployment_coordinator, :frozen_release,
                          :frozen_requestor, :plan_member_id, :parent_request_id,
                          :deployment_window_event_id, :created_from_template, :origin_request_template_id]

  def clone_request_with_dependencies(clone_attrs)
    @cloned_request = self.dup(except: EXCLUDE_FROM_REQUEST)
    @cloned_request.deployment_coordinator_id = clone_attrs[:user_id] if clone_attrs[:user_id].present?
    @cloned_request.should_time_stitch = true

    clone_attrs[:request][:plan_member_attributes].delete(:id) if clone_attrs[:request].try(:[], :plan_member_attributes)
    clone_attrs[:request][:aasm_state] = 'created'

    if clone_attrs[:request].try(:[], :uploads_attributes)
      uploads_attributes = clone_attrs[:request][:uploads_attributes]
      upload_ids = []
      uploads_attributes.keys.each do |key|
        if uploads_attributes[key].try(:[], :id)
          upload_ids << uploads_attributes[key][:id] if uploads_attributes[key]['_destroy'] == 'false'
          uploads_attributes.except!(key)
        end
      end
      clone_attrs[:request][:uploads_attributes] = uploads_attributes
    end

    @cloned_request.update_attributes(clone_attrs[:request])

    clone_dependencies(upload_ids) if @cloned_request.valid?
    @cloned_request
  end

  def clone_dependencies(upload_ids)
    Upload.find(upload_ids).each do |upload|
      @cloned_request.uploads << upload.deep_copy
    end if upload_ids

    email_recipients.each do |recipient|
      @cloned_request.email_recipients << recipient.dup
    end

    clone_steps(@cloned_request)
  end

  def clone_steps(new_request, request_params = nil)
    new_request_steps, new_request_steps_script_arguments, new_request_steps_servers = [], [], []
    new_request_sub_steps, new_request_uploads, new_request_execution_condition = [], [], []
    step_associations_to_include = [:servers, :server_aspects, :server_groups, :execution_condition, :uploads, :step_script_arguments, :notes, :installed_component,
                                    {app: [:application_environments, :application_components]}]

    new_environment_id = new_request.try(:environment_id)
    include_options = {users: true}
    step_associations = nil
    exclude_from_step = EXCLUDE_FROM_STEP
    execution_condition_hash = {}

    if request_params
      new_environment_id = request_params[:new_environment_id]
      include_options = request_params[:include_options]
      step_associations = request_params[:step_associations]
      exclude_from_step = request_params[:exclude_from_step]
    end

    req_steps = steps.top_level.includes(step_associations_to_include, {steps: step_associations_to_include})

    req_steps.each do |source|
      old_installed_component_id = source.installed_component_id
      step = source.dup(except: exclude_from_step, include: step_associations)
      step.ignore_current_script_arguments = true
      # set initial step state
      step.aasm_state = 'locked'
      #step.package_template_properties = nil
      step.request = new_request
      new_ic_id = step.get_installed_component({ 'environment_id' => new_environment_id }).try(:id)
      #logger.info "SS__ NewEnv: #{new_environment_id}, new_ic = #{new_ic_id}"

      step.installed_component_id = new_ic_id

      handle_step_versions(source, step, (include_options[:version] || include_options[:all]), new_ic_id)

      source.uploads.each do |upload|
        step.uploads << upload.deep_copy
      end

      # step.position = new_request.steps.map(&:position).sort.last + 1 if new_request.steps.present?

      step.owner = user unless include_options[:users] || include_options[:all]

      source.copy_execution_condition_to(step)
      # step.execution_condition.save unless step.execution_condition.blank?

      # the environment may have changed, so we need to pass that fact from the form
      # to the step cloner so it can take the appropriate steps to avoid populating
      # the step with arguments from another installed component environment

      #source.copy_script_arguments_to(step, request, new_environment_id)
      new_request_steps_script_arguments << Step.build_script_arguments_for(step, source, {old_installed_component_id: old_installed_component_id} )

      # when the step environment is changed, selections for servers that exist
      # are mistakenly cleared, when they should all be selected by default
      step = clone_servers(step, source, new_request, new_environment_id)
      new_request_steps         << step
      new_request_steps_servers << step.servers
      new_request_uploads       << step.uploads
      new_request_execution_condition << step.execution_condition

      source.steps.each do |sub_source|
        old_installed_component_id = source.installed_component_id
        new_sub_step = sub_source.dup(except: exclude_from_step, include: step_associations)
        new_sub_step.ignore_current_script_arguments = true
        # set initial step state
        new_sub_step.aasm_state = 'locked'
        #new_sub_step.package_template_properties = nil
        new_sub_step.request = new_request
        new_sub_step.installed_component_id = new_sub_step.get_installed_component.try(:id)

        handle_step_versions(sub_source, new_sub_step,
                             (include_options[:version] || include_options[:all]), new_sub_step.installed_component_id)

        sub_source.uploads.each do |upload|
          new_sub_step.uploads << upload.deep_copy
        end

        step.steps << new_sub_step
        # user.steps << new_sub_step unless include_options[:users] || include_options[:all]
        new_sub_step.owner = user unless include_options[:users] || include_options[:all]

        new_request_steps_script_arguments << Step.build_script_arguments_for(new_sub_step, sub_source, {old_installed_component_id: old_installed_component_id} )
        new_sub_step              = clone_servers(new_sub_step, sub_source, new_request, new_environment_id)
        new_request_sub_steps     << new_sub_step
        new_request_steps_servers << new_sub_step.servers
        new_request_uploads       << new_sub_step.uploads
      end
      execution_condition_hash[source.number] = source.execution_condition.try(:referenced_step).try(:number) if source.execution_condition
    end

    bulk_create_steps(new_request, new_request_steps, new_request_steps_script_arguments, new_request_steps_servers,
                      new_request_sub_steps, new_request_uploads, new_request_execution_condition) #, new_request_sub_steps_script_arguments, new_request_sub_steps_servers)

    Step.update_execution_condition(execution_condition_hash, new_request)
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

  def bulk_create_steps(new_request, new_request_steps, new_request_steps_script_arguments, new_request_steps_servers, new_request_sub_steps, new_request_uploads, new_request_execution_condition)
    # bulk create top_level steps or procedures
    # rails do not handle mass insert hence persisted objects do not have ids and
    # are considered not persisted
    Step.import(new_request_steps, validate: false)
    bulk_create_steps_substeps(new_request, new_request_steps, new_request_sub_steps)

    # get newly created steps in the right order
    # `limit` is include to make a query uniq because of the original query was cached within the transaction
    # and returns an invalid results, at least at OracleDB
    steps = new_request.steps.top_level.includes(:steps).limit(100000).map{|s| [s,s.steps]}.flatten

    bulk_create_script_args(steps, new_request_steps_script_arguments)
    bulk_create_uploads(steps, new_request_uploads)
    create_execution_condition_for(steps, new_request_execution_condition)
    # associate steps with servers
    create_step_servers(steps, new_request_steps_servers)
  end

  def create_execution_condition_for(steps, new_request_execution_condition)
    steps = steps.reject{|step| !step.parent_id.nil? }
    steps.each_with_index do |step, i|
      next if new_request_execution_condition[i].nil?
      execution_condition         = new_request_execution_condition[i]
      execution_condition.step_id = step.id
      execution_condition.save!
    end
  end

  def bulk_create_steps_substeps(new_request, new_request_steps, new_request_sub_steps)
    # after bulk top_level steps creation, update sub-steps parent_id with top_level step ids
    set_parent_for_substeps(new_request, new_request_steps)

    # bulk create steps sub-steps
    Step.import(new_request_sub_steps, validate: false)
  end

  def bulk_create_uploads(new_request_steps, new_request_uploads)
    new_request_step_ids = new_request_steps.map(&:id)
    set_step_for_upload(new_request_step_ids, new_request_uploads)
    uploads = new_request_uploads.compact.reject{|upload| upload.empty?}.flatten
    # it turns out upload were saved before by `deep_copy` method
    # TODO: refactor Upload.deep_copy to make it not save the copied instance and uncomment this line
    # Upload.import(uploads)
  end

  def bulk_create_script_args(new_request_steps, new_request_steps_script_arguments)
    new_request_step_ids = new_request_steps.map(&:id)
    set_step_for_script_arguments(new_request_step_ids, new_request_steps_script_arguments)
    steps_script_arguments = new_request_steps_script_arguments.compact.reject{|script_arguments| script_arguments.empty?}.flatten
    StepScriptArgument.import(steps_script_arguments)
  end

  # creates association for server <-> step
  def create_step_servers(new_request_steps, new_request_steps_servers)
    new_request_steps_servers.each_with_index do |step_servers, i|
      next if step_servers.empty?
      new_request_steps[i].servers << step_servers
    end
  end

  # TODO: this should set the owner on the object level
  def set_step_for_upload(new_request_step_ids, new_request_uploads)
    new_request_uploads.each_with_index do |uploads, i|
      next if uploads.empty?
      uploads.each do |upload|
        upload.update_column(:owner_id, new_request_step_ids[i])
        upload.update_column(:owner_type, 'Step')
      end
    end
  end

  # set script argument step_id to step.id
  def set_step_for_script_arguments(new_request_step_ids, new_request_steps_script_arguments)
    new_request_steps_script_arguments.each_with_index do |script_arguments, i|
      next if script_arguments.nil?
      script_arguments.each{|script_argument| script_argument.step_id = new_request_step_ids[i] }
    end
  end

  def set_parent_for_substeps(new_request, new_request_steps)
    # get newly created step ids
    new_request_step_ids = new_request.steps.top_level.pluck(:id)

    # set parent_id for steps sub-steps
    new_request_steps.each_with_index do |step, i|
      step.steps.each{|sub_step| sub_step.parent_id = new_request_step_ids[i] }
    end
  end

  def clone_servers(new_step, source_step, request, new_environment_id = nil)
    return new_step if source_step.targeted_servers.blank?
    if new_environment_id.nil? || request.has_same_env_as?(source_step.request)
       server_ids_hash = { server_ids: source_step.server_ids, server_aspect_ids: source_step.server_aspect_ids }
    else
      if source_step.installed_component.present?
        ic = new_step.get_installed_component({'component_id' => source_step.component.id, 'environment_id' => new_environment_id})
        if ic.present? && ic.server_associations.present?
          server_type = "#{ic.server_associations.first.class.to_s.underscore}_ids"
          server_ids_hash = { server_type => ic.server_association_ids }
        end
      end
    end
    new_step.assign_attributes(server_ids_hash)
    new_step
  end

end