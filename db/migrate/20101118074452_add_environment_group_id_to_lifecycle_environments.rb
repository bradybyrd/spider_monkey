################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddEnvironmentGroupIdToLifecycleEnvironments < ActiveRecord::Migration
  def self.up
    add_column :lifecycle_environments, :environment_group_id, :integer
  end

  def self.down
    remove_column :lifecycle_environments, :environment_group_id
  end
end
