class AdjustingFieldsNullsIndexesOnLifecycleMembers < ActiveRecord::Migration
  def self.up
    # clean up now rolled-back multi-item request ids
    remove_index :lifecycle_members, :app_id
    remove_index :lifecycle_members, :server_id
    remove_index :lifecycle_members, :server_aspect_id
    remove_column :lifecycle_members, :app_id
    remove_column :lifecycle_members, :server_id
    remove_column :lifecycle_members, :server_aspect_id

    # add a new position column for acts as list ordering within stages
    add_column :lifecycle_members, :position, :integer
    add_index :lifecycle_members, [:lifecycle_stage_id, :position], :name => 'i_lm_lsi_pos'

    # adjust the treatment of null values
    remove_index :lifecycle_members, :column => :lifecycle_id
    change_column :lifecycle_members, :lifecycle_id, :integer, :null => false
    add_index :lifecycle_members, :lifecycle_id
    
    add_index :lifecycle_members, :lifecycle_stage_status_id, :name => 'i_lm_lssi'

  end

  def self.down
    add_column :lifecycle_members, :app_id, :integer
    add_column :lifecycle_members, :server_id, :integer
    add_column :lifecycle_members, :server_aspect_id, :integer
    add_index :lifecycle_members, :app_id
    add_index :lifecycle_members, :server_id
    add_index :lifecycle_members, :server_aspect_id

    remove_column :lifecycle_members, :position
    remove_index :lifecycle_members, [:lifecycle_stage_id, :position], :name => 'i_lm_lsi_pos'

    change_column :lifecycle_members, :lifecycle_id, :integer, :null => true

    remove_index :lifecycle_members, :lifecycle_stage_status_id, :name => 'i_lm_lssi'
  end
end
