################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnWorkspaceDataAvailableInProjectServers < ActiveRecord::Migration
  def self.up
    add_column :project_servers, :workspace_data_available, :boolean, :default => false
  end

  def self.down
    remove_column :project_servers, :workspace_data_available
  end
end
