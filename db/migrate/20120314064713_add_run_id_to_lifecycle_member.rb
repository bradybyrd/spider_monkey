class AddRunIdToLifecycleMember < ActiveRecord::Migration
  def self.up
    add_column :lifecycle_members, :run_id, :integer
    add_column :lifecycle_members, :run_position, :integer, :default => 0, :null => false
    add_index :lifecycle_members, :run_id
    add_index :lifecycle_members, [:run_id, :run_position ]
  end

  def self.down
    remove_index :lifecycle_members, :run_id
    remove_index :lifecycle_members, [:run_id, :run_position ]
    remove_column :lifecycle_members, :run_position
    remove_column :lifecycle_members, :run_id
  end
end
