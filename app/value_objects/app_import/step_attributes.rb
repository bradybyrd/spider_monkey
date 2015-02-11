module AppImport
  class StepAttributes
    attr_reader :step_attributes

    def initialize(step_attributes)
      @step_attributes = step_attributes
    end

    def belongs_to_procedure?
      step_procedure_attributes.present?
    end

    def step_procedure_attributes
      step_attributes['parent']
    end

    def procedure_name
      step_procedure_attributes['name']
    end

    def name
      step_attributes['name']
    end

    def owner_type
      step_attributes['owner_type'] || 'User'
    end

    def script
      step_attributes
      {
          name: step_attributes['script']['name'],
          type: step_attributes['script_type'],
          content: step_attributes['script']['content'],
          description: step_attributes['script']['description'],
          automation_type: step_attributes['script']['automation_type'],
          automation_category: step_attributes['script']['automation_category']
      }.merge(step_script_arguments)
    end

    def step_script_arguments
      {
          step_script_arguments:
              (step_attributes['step_script_arguments'] || []).map do |step_script_argument_attributes|
                step_script_argument(step_script_argument_attributes)
              end
      }
    end

    def step_script_argument(step_script_argument)
      {
          value: step_script_argument['value'],
          script_argument_id: step_script_argument['script_argument_id'],
          script_argument_type: step_script_argument['script_argument_type']
      }
    end

  end
end