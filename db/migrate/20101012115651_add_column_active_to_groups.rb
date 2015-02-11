################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnActiveToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :active, :boolean, :default => true
  end

  def self.down
    remove_column :groups, :active
  end
end
