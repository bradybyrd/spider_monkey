################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateTeamsGroups < ActiveRecord::Migration
  def self.up
    create_table :teams_groups do |t|
      t.integer :group_id
      t.integer :team_id
      t.timestamps
    end
  end

  def self.down
    drop_table :teams_groups
  end
end
