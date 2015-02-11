class ChangeColumnValueOfStepScriptArgumentToText26 < ActiveRecord::Migration
  def up
    change_column :step_script_arguments, "value", :string, :limit => 4000
  end

  def down
    change_column :step_script_arguments, "value", :string
  end
end
