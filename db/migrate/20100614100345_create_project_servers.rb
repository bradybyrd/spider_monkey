################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateProjectServers < ActiveRecord::Migration
  def self.up
    create_table :project_servers do |t|
      t.integer :server_name_id
      t.string  :name
      t.string  :ip
      t.string  :server_url
      t.integer :port
      t.string  :username
      t.string  :password
      t.timestamps
    end
  end

  def self.down
    drop_table :project_servers
  end
end
