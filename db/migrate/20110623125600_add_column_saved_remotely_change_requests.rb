################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnSavedRemotelyChangeRequests < ActiveRecord::Migration
  def self.up
    add_column :change_requests, :saved_remotely, :boolean, :default => true
  end

  def self.down
    remove_column :change_requests, :saved_remotely
  end
end
