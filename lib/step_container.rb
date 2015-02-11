################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module StepContainer
  def each_step_phase
    rval_steps = []

    the_steps = self.is_a?(Request) ? steps.top_level : steps
    the_steps = the_steps.includes(:request, :execution_condition, parent: :execution_condition)

    the_steps.each do |step|
      if step.different_level_from_previous?
        yield(rval_steps) unless rval_steps.empty?
        rval_steps = [step]
      else
        rval_steps << step
      end
    end

    yield(rval_steps)
  end

  def lock_steps
    [steps.problem + steps.ready_or_in_process].flatten.each { |step| 
      step.state_changer = state_changer if state_changer
      step.lock! if step.only_procedures_from_in_process?
    }
  end

  def prepare_steps_for_execution(last_completed_step = nil)
    each_step_phase do |steps|
      next if steps.all? { |step| step.complete_or_not_executable? }
      break if last_completed_step && steps.include?(last_completed_step)
      steps.each { |step|
        meets_execution_condition = (self.respond_to?(:procedure) && self.procedure) ? meets_execution_condition? : true
        if step.should_execute? && meets_execution_condition
          step.state_changer = self.state_changer if self.state_changer
          step.prepare_for_work!
          add_errors_from_step(step)
        end
      }
      break
    end
  end

  def add_assorted_steps(new_steps)
    @new_steps = new_steps
    
    step_position = 1
    @new_steps.each{ |step|
      step[:position] = step_position.to_s
      step_position = step_position + 1
    }
    add_steps(new_steps)
  end

  def add_errors_from_step(step)
    step.errors.each do |key, value|
      self.errors.add(key, value)
    end
  end
end
