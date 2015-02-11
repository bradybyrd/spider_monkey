################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddDirectAccessToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :direct_access, :boolean, :default => false
  end

  def self.down
    remove_column :users, :direct_access
  end
end
