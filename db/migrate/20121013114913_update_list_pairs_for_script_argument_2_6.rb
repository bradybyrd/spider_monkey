class UpdateListPairsForScriptArgument26 < ActiveRecord::Migration
  def up
	change_column :script_arguments, "list_pairs", :string, :limit => 4000
  end

  def down
    change_column :script_arguments, "list_pairs", :string  	
  end
end
