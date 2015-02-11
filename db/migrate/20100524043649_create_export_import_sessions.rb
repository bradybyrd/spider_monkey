################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateExportImportSessions < ActiveRecord::Migration
  def self.up
    create_table :export_import_sessions do |t|
      t.string :user_name
      t.integer :user_id
      t.boolean :checked_out
      t.timestamps
    end
  end

  def self.down
    drop_table :export_import_sessions
  end
end
