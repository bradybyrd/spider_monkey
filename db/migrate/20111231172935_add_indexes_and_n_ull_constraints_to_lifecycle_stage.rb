class AddIndexesAndNUllConstraintsToLifecycleStage < ActiveRecord::Migration
  def self.up
    change_column :lifecycle_stages, :name, :string, :null => false
    change_column :lifecycle_stages, :auto_start, :boolean, :null => false, :default => false
    add_index :lifecycle_stages, :position, :name => "i_lc_stages_position"
    add_index :lifecycle_stages, :auto_start, :name => "i_lc_stages_auto_start"
    add_index :lifecycle_stages, :name, :name => "i_lc_stages_name"
  end

  def self.down
    change_column :lifecycle_stages, :name, :string, :null => true
    change_column :lifecycle_stages, :auto_start, :boolean, :null => true, :default => false
    remove_index :lifecycle_stages, :position, :name => "i_lc_stages_position"
    remove_index :lifecycle_stages, :auto_start, :name => "i_lc_stages_auto_start"
    remove_index :lifecycle_stages, :name, :name => "i_lc_stages_name"
  end
end
