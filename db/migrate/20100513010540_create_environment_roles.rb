################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateEnvironmentRoles < ActiveRecord::Migration
  def self.up
    create_table :environment_roles do |t|
      t.integer :user_id
      t.integer :environment_id
      t.boolean :visible, :default => false
      t.string  :role
      t.timestamps
    end
  end

  def self.down
    drop_table :environment_roles
  end
end
