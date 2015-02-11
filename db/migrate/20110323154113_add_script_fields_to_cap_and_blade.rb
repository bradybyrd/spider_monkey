################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddScriptFieldsToCapAndBlade < ActiveRecord::Migration
  def self.up
    add_column :capistrano_scripts, :integration_id, :integer
    add_column :capistrano_scripts, :template_script_id, :integer
    add_column :capistrano_scripts, :template_script_type, :string
    add_column :bladelogic_scripts, :integration_id, :integer
    add_column :bladelogic_scripts, :template_script_id, :integer
    add_column :bladelogic_scripts, :template_script_type, :string
  end

  def self.down
    remove_column :capistrano_scripts, :integration_id
    remove_column :capistrano_scripts, :template_script_id
    remove_column :capistrano_scripts, :template_script_type
    remove_column :bladelogic_scripts, :integration_id
    remove_column :bladelogic_scripts, :template_script_id
    remove_column :bladelogic_scripts, :template_script_type
  end
end
