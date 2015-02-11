class ChangeRunPositionToParallelForRuns < ActiveRecord::Migration
  def self.up
    remove_index :lifecycle_members, :run_id
    remove_index :lifecycle_members, [:run_id, :run_position ]
    remove_column :lifecycle_members, :run_position
    add_column :lifecycle_members, :parallel, :boolean, :null => false, :default => false
    add_index :lifecycle_members, :parallel
  end

  def self.down
    add_column :lifecycle_members, :run_position, :integer, :default => 0, :null => false
    add_index :lifecycle_members, :run_id
    add_index :lifecycle_members, [:run_id, :run_position ]
    remove_index :lifecycle_members, :parallel
    remove_column :lifecycle_members, :parallel
  end
end
