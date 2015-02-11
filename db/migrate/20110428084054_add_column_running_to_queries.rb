################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnRunningToQueries < ActiveRecord::Migration
  def self.up
    add_column :queries, :running, :boolean, :default => false
  end

  def self.down
    remove_column :queries, :running
  end
end
