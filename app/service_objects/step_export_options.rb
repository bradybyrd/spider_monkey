class StepExportOptions

  attr_reader :options

  def initialize(include_automations = false)
    @include_automations = include_automations
    @options = steps_hash
  end

  private

  def export_automations?
    @include_automations
  end

  def steps_hash
    if export_automations?
      steps_hash_with_script
    else
      steps_hash_without_scripts
    end
  end

  def steps_hash_with_script
    steps_with_scripts = steps_hash_without_scripts.dup
    steps_with_scripts[:include][:script] = { only: step_script_attributes }
    steps_with_scripts[:include][:step_script_arguments] =
        {
            only: [:value, :script_argument_id, :script_argument_type] ,
            include: {
                script_argument: {
                    only: [:name, :argument, :argument_type, :position],
                    include: {
                        script: { only: [:name, :template_script_type] }
                    }
                }
            }
        }
    steps_with_scripts[:methods] = :resource_automation_script
    steps_with_scripts
  end

  def steps_hash_without_scripts
    {
        only: [ :name, :aasm_state, :component_version, :description, :start_by,
                :complete_by, :suppress_notification, :default_tab, :execute_anytime,
                :different_level_from_previous, :start_by, :complete_by, :own_version,
                :estimate, :protected_step, :should_execute, :procedure, :owner_type,
                :script_type,:latest_package_instance,:create_new_package_instance],
        include: {
            component: { only: [:name] },
            package: { only: [:name] },
            package_instance: { only: [:name] },
            owner: { only: [:name],  methods: [:name] },
            work_task: { only: [:name] },
            notes: { only: [:content], methods: [:user_name] },
            phase: { only: [:name, :position, :archive_number, :archived_at] },
            runtime_phase: { only: [:name, :position] },
            parent: { only: [:name] },
            temporary_property_values: { only: [:value, :original_value_holder_type], methods: [:property_name,:holder_name] },
        }
    }
  end

  def step_script_attributes
    [:name, :automation_category, :automation_type, :content, :description]
  end

end