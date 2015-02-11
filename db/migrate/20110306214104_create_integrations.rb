################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateIntegrations < ActiveRecord::Migration
  def self.up
    create_table :integrations do |t|
      t.string  :name
      t.string  :integration_type
      t.string  :dns
      t.string  :server_url
      t.integer :port
      t.string  :username
      t.string  :password
      t.text    :connection_params
      t.text    :description
      t.timestamps
    end
  end

  def self.down
    drop_table :integrations
  end
end
