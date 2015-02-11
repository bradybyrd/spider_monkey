################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ChangeTeamUserIdColumnOfTeamRoles < ActiveRecord::Migration
  def self.up
    rename_column :teams_roles, :teams_user_id, :user_id
    add_column    :teams_roles,  :team_id, :integer
  end

  def self.down
    rename_column :teams_roles, :user_id, :teams_user_id
    remove_column :teams_roles, :team_id
  end
end
