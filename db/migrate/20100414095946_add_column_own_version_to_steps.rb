################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnOwnVersionToSteps < ActiveRecord::Migration
  def self.up
    add_column :steps, :own_version, :boolean, :default => false
  end

  def self.down
    remove_column :steps, :own_version
  end
end
