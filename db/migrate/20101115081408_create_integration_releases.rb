################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateIntegrationReleases < ActiveRecord::Migration
  def self.up
    create_table :integration_releases do |t|
      t.string  :name
      t.integer :integration_project_id
      t.boolean :active, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :integration_releases
  end
end
