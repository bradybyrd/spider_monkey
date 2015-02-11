################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateGroupedEnvironments < ActiveRecord::Migration
  def self.up
    create_table :grouped_environments do |t|
      t.integer :environment_group_id
      t.integer :environment_id
      t.timestamps
    end
    add_index :grouped_environments, :environment_group_id
    add_index :grouped_environments, :environment_id
  end

  def self.down
    drop_table :grouped_environments
  end
end
