################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateTeams < ActiveRecord::Migration
  def self.up
    create_table :teams do |t|
      t.string :name
      t.integer :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :teams
  end
end
