################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateAppsBusinessProcesses < ActiveRecord::Migration
  def self.up
    create_table :apps_business_processes do |t|
      t.integer :app_id
      t.integer :business_process_id
      t.timestamps
    end
  end

  def self.down
    drop_table :apps_business_processes
  end
end
