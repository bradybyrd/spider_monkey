################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddReleaseIdInLifecycles < ActiveRecord::Migration
  def self.up
    add_column :lifecycles, :release_id, :integer
  end

  def self.down
    remove_column :lifecycles, :release_id
  end
end
