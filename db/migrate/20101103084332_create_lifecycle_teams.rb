################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateLifecycleTeams < ActiveRecord::Migration
  def self.up
    create_table :lifecycle_teams do |t|
      t.integer :lifecycle_id
      t.integer :team_id
      t.timestamps
    end
  end

  def self.down
    drop_table :lifecycle_teams
  end
end
