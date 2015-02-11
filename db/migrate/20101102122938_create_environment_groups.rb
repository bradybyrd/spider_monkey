################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateEnvironmentGroups < ActiveRecord::Migration
  def self.up
    create_table :environment_groups do |t|
      t.string :name
      t.integer :app_id
      t.timestamps
    end
    add_index :environment_groups, :app_id
  end

  def self.down
    drop_table :environment_groups
  end
end
