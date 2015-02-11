################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateLifecycleWikis < ActiveRecord::Migration
  def self.up
    create_table :lifecycle_wikis do |t|
      t.text :content
      t.string :subject
      t.integer :lifecycle_id
      t.integer :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :lifecycle_wikis
  end
end
