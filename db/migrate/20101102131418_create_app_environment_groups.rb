################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateAppEnvironmentGroups < ActiveRecord::Migration
  def self.up
    create_table :app_environment_groups do |t|
      t.integer :app_id
      t.integer :environment_group_id
      t.integer :environment_id
      t.timestamps
    end
    
    add_index :app_environment_groups, :app_id
    add_index :app_environment_groups, :environment_group_id
    add_index :app_environment_groups, :environment_id
    
  end

  def self.down
    drop_table :app_environment_groups
  end
end
