################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddIsactiveColumnProjectServers < ActiveRecord::Migration
  def self.up
    add_column :project_servers, :is_active, :boolean, :default => true
  end

  def self.down
    remove_column :project_servers, :is_active
  end
end
