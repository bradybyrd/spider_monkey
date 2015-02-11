module StepService
  module ScriptImporter
    class AutomationScriptAssociater < ScriptAssociater
      def initialize(step, script, script_attributes)
        @step = step
        @script = script
        @script_attributes = script_attributes
      end

      def associate_imported_scripts
        assign_to_step
        set_arguments_values
      end

      private

      def set_step_script_type
        step.script_type = step.script.automation_category
      end

    end
  end
end