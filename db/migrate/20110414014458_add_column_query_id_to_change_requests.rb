################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnQueryIdToChangeRequests < ActiveRecord::Migration
  def self.up
    add_column :change_requests, :query_id, :integer
  end

  def self.down
    remove_column :change_requests, :query_id
  end
end