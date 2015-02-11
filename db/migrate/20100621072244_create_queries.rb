################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateQueries < ActiveRecord::Migration
  def self.up
    create_table :queries do |t|
      t.integer :project_server_id
      t.integer :lifecycle_id
      t.timestamps
    end
  end

  def self.down
    drop_table :queries
  end
end
