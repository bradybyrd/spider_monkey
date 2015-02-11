################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnDeletedRemotelyChangeRequests < ActiveRecord::Migration
  def self.up
    add_column :change_requests, :deleted_remotely, :boolean, :default => false
  end

  def self.down
    remove_column :change_requests, :deleted_remotely
  end
end
