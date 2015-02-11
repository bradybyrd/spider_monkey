################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateChangeRequests < ActiveRecord::Migration
  def self.up
    create_table :change_requests do |t|
      t.integer :project_server_id
      t.integer :lifecycle_id
      t.integer :tab_id
      t.string  :number
      t.text    :short_description
      t.string  :assigned_to
      t.string  :expected_start
      t.string  :location
      t.string  :due_date
      t.timestamps
    end
  end

  def self.down
    drop_table :change_requests
  end
end
