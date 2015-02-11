module StepService
  module ScriptImporter
    class BladelogicScriptAssociater < ScriptAssociater
      BLADELOGIC_SCRIPT_TYPE = 'BladelogicScript'

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
        step.script_type = BLADELOGIC_SCRIPT_TYPE
      end

    end
  end
end