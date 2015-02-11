################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnTimezoneInUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :time_zone, :string
  end

  def self.down
    remove_column :users, :time_zone
  end
end
