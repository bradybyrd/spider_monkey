################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateAppsRequests < ActiveRecord::Migration
  def self.up
    create_table :apps_requests do |t|
      t.integer :request_id
      t.integer :app_id
      t.timestamps
    end
  end

  def self.down
    drop_table :apps_requests
  end
end
