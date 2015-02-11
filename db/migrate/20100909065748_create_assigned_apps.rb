################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateAssignedApps < ActiveRecord::Migration
  def self.up
    create_table :assigned_apps do |t|
      t.integer :user_id
      t.integer :app_id
      t.timestamps
    end
  end

  def self.down
    drop_table :assigned_apps
  end
end
