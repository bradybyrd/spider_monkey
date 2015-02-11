class Step < ActiveRecord::Base

  class << self
    def import_app(request, steps_xml_hash, app, importing_user)
      build_steps(request, steps_xml_hash, app, importing_user)
    end

    def build_steps(request, key, app, importing_user)
      if key["steps"].present?
        request.steps.top_level.destroy_all
        key["steps"].each do |xml_hash|
          build_step(request, xml_hash, app, importing_user)
        end
      end
    end

    def build_step(request, xml_hash, app, importing_user)
      step_attributes = step_attributes(xml_hash)
      owner_id = find_owner(xml_hash)
      step = Step.create!(name: step_attributes.name, owner_id: owner_id, owner_type: step_attributes.owner_type, request_id: request.id, app_id: app.id)
      step.work_task_id = WorkTask.import_app(xml_hash)
      step.component_id = Component.import_app_request(xml_hash)
      step.version_tag_id = VersionTagImport.version_tag_id_from_hash(xml_hash)
      assign_step_to_procedure(step, request, step_attributes.procedure_name) if step_attributes.belongs_to_procedure?
      update_installed_component(request, app, step) if step.component_id.present?
      update_component_version(step, xml_hash)
      Package.import_app_request(step, xml_hash)
      PackageInstance.import_app_request(step, xml_hash)
      temporary_property_value_attributes(step, xml_hash)
      Note.import_app(step, xml_hash, 'Step')
      StepService::ScriptImporter::ScriptAssociater.new(step, step_attributes.script).associate_imported_scripts
      PhaseImport.new(step, xml_hash).import!
      update_step_attributes(step, xml_hash)
      step
    end

    def update_step_attributes(step, step_hash)
      exclude_from_step = ['component', 'work_task', 'owner', 'owner_type', 'notes', 'parent','resource_automation_script', 'temporary_property_values', 'package', 'package_instance', 'step_script_arguments', 'phase', 'runtime_phase', 'script']
      step_params = step_hash.delete_if { |key, val| exclude_from_step.include?(key) }
      step_params["estimate"] = Request.convert_estimate(step_params["estimate"]) if step_params["estimate"].present?
      step_params["start_by"] = expose_time_for_selector(step_params["start_by"])
      step.update_attributes!(step_params)
    end

    def assign_step_to_procedure(step, request, procedure_name)
      procedure = request.procedures.where(name: procedure_name).last
      step.parent = procedure if procedure
    end

    def update_component_version(step, xml_hash)
      if xml_hash["component-version"]
        step.component_version = xml_hash["component-version"].first
      end
    end

    def find_owner(xml_hash)
      if xml_hash["owner_type"] == 'Group'
        group = Group.find_by_name(xml_hash["owner"]["name"].first) || User.current_user.groups.first
        group.id
      else
        find_user_owner_id(xml_hash['owner'])
      end
    end

    def find_user_owner_id(owner_hash)
      if owner_hash.present?
        ownername = owner_hash["name"].split(',')
        user = User.find_by_last_name_and_first_name(ownername[0].squish, ownername[1].squish)
      end
      user_id(user)
    end

    def user_id(user)
      if user.present?
        user.id
      else
        User.current_user.id
      end
    end

    def update_installed_component(request, app, step)
      app_component = ApplicationComponent.where(app_id: app.id, component_id: step.component_id).first
      app_environment = ApplicationEnvironment.where(app_id: app.id, environment_id: request.environment_id).first
      if app_component && app_environment
        installed_component = InstalledComponent.where(application_component_id: app_component.id, application_environment_id: app_environment.id).first
        if installed_component.present?
          step.installed_component_id = installed_component.id
          step.app_id = app.id
        end
      end
    end

    def step_attributes(xml_hash)
      AppImport::StepAttributes.new(xml_hash)
    end

    def temporary_property_value_attributes(step, xml_hash)
      if xml_hash["temporary_property_values"]
        temp_value_attributes = AppImport::TemporaryPropertyValuesAttributes.new(step, xml_hash)
        temp_value_attributes.import_app_request
      end
    end

  end
end