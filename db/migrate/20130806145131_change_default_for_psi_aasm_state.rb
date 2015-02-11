class ChangeDefaultForPsiAasmState < ActiveRecord::Migration
  def up
    change_column :plan_stage_instances, :aasm_state, :string, :null => false, :default => 'compliant'
  end

  def down
    change_column :plan_stage_instances, :aasm_state, :string, :null => false, :default => 'created'
  end
end
