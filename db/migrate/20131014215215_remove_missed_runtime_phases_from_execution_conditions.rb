class RemoveMissedRuntimePhasesFromExecutionConditions < ActiveRecord::Migration
  def change
    cond_ids = StepExecutionCondition.joins("LEFT OUTER JOIN Runtime_phases ON Step_execution_conditions.runtime_phase_id=Runtime_phases.id")
    .where("Step_execution_conditions.condition_type='runtime_phase' and Runtime_phases.id IS NULL").map(&:id).compact.sort.uniq

    while (sub_cond_ids = cond_ids.slice!(0..999)).size > 0 do
      StepExecutionCondition.delete(sub_cond_ids)
    end
  end
end
