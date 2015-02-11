################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateLifecycleStageDates < ActiveRecord::Migration
  def self.up
    create_table :lifecycle_stage_dates do |t|
      t.integer :lifecycle_id
      t.integer :lifecycle_stage_id
      t.date    :start_date
      t.date    :end_date
      t.timestamps
    end
    
    add_index :lifecycle_stage_dates, :lifecycle_id
    
  end

  def self.down
    drop_table :lifecycle_stage_dates
  end
end
