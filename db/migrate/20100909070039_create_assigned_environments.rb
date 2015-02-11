################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateAssignedEnvironments < ActiveRecord::Migration
  def self.up
    create_table :assigned_environments do |t|
      t.integer :assigned_app_id
      t.integer :environment_id
      t.string  :role
      t.timestamps
    end
  end

  def self.down
    drop_table :assigned_environments
  end
end
