################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnEnvironmentGroupIdToAssignedEnvironments < ActiveRecord::Migration
  def self.up
    add_column :assigned_environments, :environment_group_id, :integer
  end

  def self.down
    remove_column :assigned_environments, :environment_group_id
  end
end
