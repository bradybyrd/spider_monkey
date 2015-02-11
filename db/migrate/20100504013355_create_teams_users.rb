################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateTeamsUsers < ActiveRecord::Migration
  def self.up
    create_table :teams_users do |t|
      t.integer :team_id
      t.integer :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :teams_users
  end
end
