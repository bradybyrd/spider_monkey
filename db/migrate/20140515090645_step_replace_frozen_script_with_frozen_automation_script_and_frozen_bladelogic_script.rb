class StepReplaceFrozenScriptWithFrozenAutomationScriptAndFrozenBladelogicScript < ActiveRecord::Migration
  def up
    remove_column :steps, :frozen_script
    add_column :steps, :frozen_automation_script, :binary
    add_column :steps, :frozen_bladelogic_script, :binary
  end

  def down
    add_column :steps, :frozen_script, :binary
    remove_column :steps, :frozen_automation_script
    remove_column :steps, :frozen_bladelogic_script
  end
end
