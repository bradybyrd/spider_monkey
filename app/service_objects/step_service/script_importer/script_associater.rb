module StepService
  module ScriptImporter
    class ScriptAssociater
      attr_reader :step, :script_attributes, :script

      def initialize(step, script_attributes)
        @step = step
        @script_attributes = script_attributes
      end

      def associate_imported_scripts
        associater.associate_imported_scripts
      end

      private

      def assign_to_step
        step.script = script
        set_step_script_type
        mark_step_as_automatic
      end

      def set_arguments_values
        script_attributes[:step_script_arguments].each do |step_script_argument_attributes|
          step.step_script_arguments.build(step_script_argument_attributes)
        end
      end

      def mark_step_as_automatic
        step.manual = false
      end

      def set_step_script_type
        raise NotImplementedError
      end

      def associater
        ScriptAssociaterFactory.new(step, script_attributes).instance
      end

    end
  end
end