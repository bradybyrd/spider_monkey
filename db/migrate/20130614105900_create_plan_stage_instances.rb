class CreatePlanStageInstances < ActiveRecord::Migration
  def change
    create_table :plan_stage_instances do |t|
      t.integer :plan_id, :null => false
      t.integer :plan_stage_id, :null => false
      t.string :aasm_state, :null => false, :default => 'created'
      t.datetime :archived_at
      t.string :archive_number

      t.timestamps
    end
    add_index :plan_stage_instances, :plan_id, :name => 'I_PSI_plan_id'
    add_index :plan_stage_instances, :plan_stage_id, :name => 'I_PSI_plan_stage_id'
    add_index :plan_stage_instances, :aasm_state, :name => 'I_PSI_aasm_state'
    add_index :plan_stage_instances, :archived_at, :name => 'I_PSI_archived_at'
    add_index :plan_stage_instances, :archive_number, :name => 'I_PSI_archive_number'
  end
end
