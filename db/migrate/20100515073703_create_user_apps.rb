################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateUserApps < ActiveRecord::Migration
  def self.up
    create_table :user_apps do |t|
      t.integer :user_id
      t.integer :app_id
      t.text    :roles
      t.boolean :visible, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :user_apps
  end
end
