################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateIntegrationCsvs < ActiveRecord::Migration
  def self.up
    create_table :integration_csvs do |t|
      t.string :name
      t.integer :project_server_id
      t.integer :lifecycle_id
      t.timestamps
    end
  end

  def self.down
    drop_table :integration_csvs
  end
end
