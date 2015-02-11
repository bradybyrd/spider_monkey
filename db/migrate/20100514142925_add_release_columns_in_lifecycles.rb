################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddReleaseColumnsInLifecycles < ActiveRecord::Migration
  def self.up
    add_column :lifecycles, :release_manager_id, :integer
    add_column :lifecycles, :release_date, :date
  end

  def self.down
    remove_column :lifecycles, :release_manager_id
    remove_column :lifecycles, :release_date
  end
end
