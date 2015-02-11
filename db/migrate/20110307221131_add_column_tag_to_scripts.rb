################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnTagToScripts < ActiveRecord::Migration
  def self.up
    remove_index :scripts, :name => 'scripts_by_class'
    remove_column :scripts, :script_class
    add_column    :scripts, :tag_id, :string
  end

  def self.down
    add_column :scripts, :script_class, :string
    add_index :scripts, [:script_class], :name => 'scripts_by_class'
    remove_column :scripts, :tag_id
  end
end
