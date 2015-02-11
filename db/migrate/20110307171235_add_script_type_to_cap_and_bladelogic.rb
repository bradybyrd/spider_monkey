################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddScriptTypeToCapAndBladelogic < ActiveRecord::Migration
  def self.up
    add_column :bladelogic_scripts, :script_class, :string
    add_column :capistrano_scripts, :script_class, :string
    add_column :bladelogic_scripts, :script_type, :string
    add_column :capistrano_scripts, :script_type, :string
    add_column :scripts, :script_class, :string
    add_index :scripts, [:script_class], :name => 'scripts_by_class'
  end

  def self.down
    remove_column :bladelogic_scripts, :script_class
    remove_column :capistrano_scripts, :script_class
    remove_column :bladelogic_scripts, :script_type
    remove_column :capistrano_scripts, :script_type
    remove_column :scripts, :script_class
  end
end
