################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddDetailsToProjectServers < ActiveRecord::Migration
  def self.up
    add_column :project_servers, :details, :text
  end

  def self.down
    remove_column :project_servers, :details
  end
end
