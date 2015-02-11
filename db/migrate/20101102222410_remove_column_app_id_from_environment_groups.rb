################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class RemoveColumnAppIdFromEnvironmentGroups < ActiveRecord::Migration
  def self.up
    remove_index :environment_groups, :column => :app_id
    remove_column :environment_groups, :app_id
    add_column :environment_groups, :active, :boolean, :default => false
  end

  def self.down
    add_column :environment_groups, :app_id, :integer
    add_index :environment_groups, :app_id
    remove_column :environment_groups, :active
  end
end
