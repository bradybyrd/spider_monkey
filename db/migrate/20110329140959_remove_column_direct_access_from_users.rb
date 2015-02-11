################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class RemoveColumnDirectAccessFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :direct_access
  end

  def self.down
    add_column :users, :direct_access, :boolean, :default => false
  end
end
