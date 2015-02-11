################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnOnLifecycleToSteps < ActiveRecord::Migration
  def self.up
    add_column :steps, :on_lifecycle, :boolean, :default => false
  end

  def self.down
    remove_column :steps, :on_lifecycle
  end
end
