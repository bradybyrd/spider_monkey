################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddAutoStartColumnInLifecycleStages < ActiveRecord::Migration
  def self.up
    add_column :lifecycle_stages, :auto_start, :boolean, :default => false
  end

  def self.down
    remove_column :lifecycle_stages, :auto_start
  end
end
