################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumSysIdToChangeRequests < ActiveRecord::Migration
  def self.up
    add_column :change_requests, :sys_id, :string
  end

  def self.down
    remove_column :change_requests, :sys_id
  end
end
