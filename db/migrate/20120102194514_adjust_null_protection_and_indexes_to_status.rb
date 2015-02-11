class AdjustNullProtectionAndIndexesToStatus < ActiveRecord::Migration
  def self.up
    change_column :lifecycle_stage_statuses, :name, :string, :null => false
    add_index :lifecycle_stage_statuses, :name, :name => 'i_lc_st_status_lsi_name' 
    add_index :lifecycle_stage_statuses, [:lifecycle_stage_id, :position], :name => 'i_lc_st_status_lsi_pos'
  end

  def self.down
    change_column :lifecycle_stage_statuses, :name, :string, :null => true
    remove_index :lifecycle_stage_statuses, :name, :name => 'i_lc_st_status_lsi_name'
    remove_index :lifecycle_stage_statuses, [:lifecycle_stage_id, :position], :name => 'i_lc_st_status_lsi_pos'
  end
end
