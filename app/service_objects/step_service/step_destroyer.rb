module StepService
  class StepDestroyer
    attr_reader :step

    def initialize(step)
      @step = step
    end

    # procedure is also a step, so can be used both for deleting steps and procedures
    def destroy
      safe_destroy do
        step.without_auditing do
          without_callbacks do
            step.destroy
          end
        end
        destroy_execution_condition if step.procedure?
      end

      step
    end

    def destroy_execution_condition
      execution_condition = StepExecutionCondition.find_by_referenced_step_id(step.id)
      execution_condition.destroy if execution_condition
    end

    private

    def safe_destroy
      Step.transaction do
        StepExecutionCondition.transaction do
          begin
            yield
          rescue => ex
            Rails.logger.error "Step(s) could not be deleted. #{ex.backtrace}"
            raise ActiveRecord::Rollback
          end
        end
      end
    end

    def without_callbacks
      disable_callbacks
      yield
      restore_callbacks
    end

    def disable_callbacks
      before_save_callbacks.each {|callback| Step.skip_callback(:save, :before, callback)}
      before_destroy_callbacks.each {|callback| Step.skip_callback(:destroy, :before, callback)}
    end

    def restore_callbacks
      before_save_callbacks.each {|callback| Step.set_callback(:save, :before, callback)}
      before_destroy_callbacks.each {|callback| Step.set_callback(:destroy, :before, callback)}
    end

    def before_save_callbacks
      [:stitch_package_template_id, :check_installed_component, :remove_execution_conditions]
    end

    def before_destroy_callbacks
      [:reload_position]
    end
  end
end