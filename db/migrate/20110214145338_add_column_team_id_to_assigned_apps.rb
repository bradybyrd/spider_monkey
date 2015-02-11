################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnTeamIdToAssignedApps < ActiveRecord::Migration
  def self.up
    add_column :assigned_apps, :team_id, :integer
  end

  def self.down
    remove_column :assigned_apps, :team_id
  end
end
