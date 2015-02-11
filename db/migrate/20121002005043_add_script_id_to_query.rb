class AddScriptIdToQuery < ActiveRecord::Migration
  def change
    add_column :queries, :script_id, :integer
    add_index :queries, :script_id
  end
end
