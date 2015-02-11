################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class RemoveColumnNumberFromChangeRequests < ActiveRecord::Migration
  def self.up
    remove_column :change_requests, :number
  end

  def self.down
    add_column :change_requests, :number
  end
end
