################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnIsAutomaticToLifecycleTemplates < ActiveRecord::Migration
  def self.up
    add_column :lifecycle_templates, :is_automatic, :boolean, :default => false
  end

  def self.down
    remove_column :lifecycle_templates, :is_automatic
  end
end
