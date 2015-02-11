################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateDevelopmentTeams < ActiveRecord::Migration
  def self.up
    create_table :development_teams do |t|
      t.integer :app_id
      t.integer :team_id
      t.timestamps

    end
  end

  def self.down
    drop_table :development_teams
  end
end
