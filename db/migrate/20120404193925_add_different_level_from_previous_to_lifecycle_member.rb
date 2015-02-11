class AddDifferentLevelFromPreviousToLifecycleMember < ActiveRecord::Migration
  def self.up
    add_column :lifecycle_members, :different_level_from_previous, :boolean, :default => true, :null => false
    add_index :lifecycle_members, :different_level_from_previous, :name => 'i_lm_dlfp'
  end

  def self.down
    remove_column :lifecycle_members, :different_level_from_previous
  end
end
