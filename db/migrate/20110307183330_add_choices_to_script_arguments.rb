################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddChoicesToScriptArguments < ActiveRecord::Migration
  def self.up
    add_column :script_arguments, :choices, :text
    add_column :capistrano_script_arguments, :choices, :text
    add_column :bladelogic_script_arguments, :choices, :text
  end

  def self.down
    remove_column :script_arguments, :choices
    remove_column :capistrano_script_arguments, :choices
    remove_column :bladelogic_script_arguments, :choices
  end
end
