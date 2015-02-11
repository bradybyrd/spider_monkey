class AddStrictPlanToApp < ActiveRecord::Migration
  def change
    add_column :apps, :strict_plan_control, :boolean, :default => false, :null => false
    add_index :apps, :strict_plan_control, :name => 'I_A_STRICT_PC'
  end
end
