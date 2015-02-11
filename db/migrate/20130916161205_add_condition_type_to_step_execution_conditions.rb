class AddConditionTypeToStepExecutionConditions < ActiveRecord::Migration
  def change
    add_column :step_execution_conditions, :condition_type, :string, :default => 'property'

    StepExecutionCondition.reset_column_information
    StepExecutionCondition.where('runtime_phase_id IS NULL').update_all :condition_type => 'property'
    StepExecutionCondition.where('runtime_phase_id IS NOT NULL').update_all :condition_type => 'runtime_phase'
  end
end
