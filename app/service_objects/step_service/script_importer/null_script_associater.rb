module StepService
  module ScriptImporter
    class NullScriptAssociater < ScriptAssociater
      def initialize(step)
        @step = step
      end

      def associate_imported_scripts
        step.manual = true
      end
    end
  end
end