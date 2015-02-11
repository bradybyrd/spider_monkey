class AdjustNullsOnStageDate < ActiveRecord::Migration
  def self.up
    remove_index :lifecycle_stage_dates, :column => :lifecycle_id
    change_column :lifecycle_stage_dates, :lifecycle_id, :integer, :null => false
    add_index :lifecycle_stage_dates, :lifecycle_id
    
    
    remove_index :lifecycle_stage_dates, :column => :lifecycle_stage_id
    change_column :lifecycle_stage_dates, :lifecycle_stage_id, :integer, :null => false
    add_index :lifecycle_stage_dates, :lifecycle_stage_id
    
    
    add_index :lifecycle_stage_dates, [:start_date, :end_date], :name => "i_lc_st_sd_ed"
    add_index :lifecycle_stage_dates, :end_date, :name => "i_lc_st_dates_ed"
  end

  def self.down
    remove_index :lifecycle_stage_dates, [:start_date, :end_date], :name => "i_lc_st_sd_ed"
    remove_index :lifecycle_stage_dates, :end_date, :name => "i_lc_st_dates_ed"
    change_column :lifecycle_stage_dates, :lifecycle_id, :integer, :null => true
    change_column :lifecycle_stage_dates, :lifecycle_stage_id, :integer, :null => true
  end
end
