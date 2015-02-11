################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnGlobalAccessInUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :global_access, :boolean, :default => false
  end

  def self.down
    remove_column :users, :global_access
  end
end
