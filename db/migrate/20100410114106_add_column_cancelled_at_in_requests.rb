################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnCancelledAtInRequests < ActiveRecord::Migration
  def self.up
    add_column :requests, :cancelled_at, :datetime
  end

  def self.down
    remove_column :requests, :cancelled_at
  end
end
