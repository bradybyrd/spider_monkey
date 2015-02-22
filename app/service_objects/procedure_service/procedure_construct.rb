module ProcedureService
  class ProcedureConstruct
    attr_accessor :procedure
    attr_reader :attrs_to_exclude

    def initialize(procedure)
      procedure.procedure = true # yes, this step is a procedure...
      @procedure          = procedure
    end

    # NB: Creating procedure has next bugs:
    # 1) Procedure steps do not preserve steps script arguments
    # 2) Server assignments are not preserved as well
    # 3) Steps order are not preserved in procedure
    # Hence, we do not bother here about those things at least until they got fixed
    def add_to_request(procedure_steps)
      safe_create do
        save_procedure
        build_steps(procedure_steps)
      end

      procedure
    end

    def save_procedure
      procedure.save_without_auditing
    end

    private

    def build_steps(procedure_steps)
      procedure_steps.each do |procedure_step|
        new_step = procedure.steps.build attributes_for_new_step(procedure_step, procedure.request_id)
        new_step.reference_ids = procedure_step.get_reference_ids
        new_step.save
      end
    end

    # Both `steps` and `procedure_steps` should have the same sort order
    def build_steps_script_arguments(steps, procedure_steps)
      steps.each_with_index do |step, i|
        Step.build_script_arguments_for(step, procedure_steps[i])
      end
    end

    def bulk_create_script_arguments(script_arguments)
      ScriptArgument.import(script_arguments)
    end

    def attrs_to_exclude
      @attrs_to_exclude ||= Step.column_names - List.get_list_items('IncludeInSteps')
    end

    def attributes_for_new_step(step, request_id)
      #procedure_step.attributes.merge('procedure_id' => nil, 'request_id' => procedure.request_id).
      #    merge('installed_component_id' => procedure_step.installed_component.try(:id)).
      #    delete_if { |key, value| key.in? attrs_to_exclude }
      step.attributes.merge(reference_ids: step.get_reference_ids,   procedure_id: nil, request_id: request_id).delete_if { |key| key.in? ['id'] }
    end

    def safe_create
      Step.transaction do
        begin
          yield
        rescue => ex
          Rails.logger.error "Could not create procedure. #{ex.message}"
          Rails.logger.error "Could not create procedure. #{ex.backtrace}"
          raise ActiveRecord::Rollback
        end
      end
    end

  end
end
