################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateDefaultTabs < ActiveRecord::Migration
  def self.up
    create_table :default_tabs do |t|
      t.integer :user_id
      t.string :tab_name, :default => 'Request'
      t.timestamps
    end
  end

  def self.down
    drop_table :default_tabs
  end
end
