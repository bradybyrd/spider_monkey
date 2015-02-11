class AddProtectAutomationTabToSteps < ActiveRecord::Migration
  def change
    add_column :steps, :protect_automation_tab, :boolean, :default => false, :null => false

    execute <<-SQL
      UPDATE steps SET protect_automation_tab = protected_step
    SQL
  end
end
