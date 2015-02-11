################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateExportLogs < ActiveRecord::Migration
  def self.up
    create_table :export_logs do |t|
      t.integer :user_id
      t.string :user_name
      t.text :user_roles
      t.timestamps
    end
  end

  def self.down
    drop_table :export_logs
  end
end
