################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateTeamsRoles < ActiveRecord::Migration
  def self.up
    create_table :teams_roles do |t|
      t.integer :teams_user_id
      t.integer :app_id
      t.text    :roles
      t.timestamps
    end
  end

  def self.down
    drop_table :teams_roles
  end
end
