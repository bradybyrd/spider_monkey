################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateReleaseContentItems < ActiveRecord::Migration
  def self.up
    create_table :release_content_items do |t|
      t.string :name
      t.text :description
      t.integer :lifecycle_id
      t.integer :integration_project_id
      t.integer :integration_release_id
      t.string  :schedule_state
      t.boolean :active, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :release_content_items
  end
end
