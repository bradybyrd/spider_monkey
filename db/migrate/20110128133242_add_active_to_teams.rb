################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddActiveToTeams < ActiveRecord::Migration
  def self.up
    add_column :teams, :active, :boolean, :default => true
  end

  def self.down
    remove_column :teams, :active
  end
end
