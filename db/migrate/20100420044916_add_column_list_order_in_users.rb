################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnListOrderInUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :list_order, :string, :default => 'desc'
  end

  def self.down
    remove_column :users, :list_order
  end
end
