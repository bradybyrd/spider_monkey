################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddTemplateScriptIdAndTemplateScriptTypeToScripts < ActiveRecord::Migration
  def self.up
    add_column :scripts, :template_script_id, :integer
    add_column :scripts, :template_script_type, :string
  end

  def self.down
    remove_column :scripts, :template_script_id
    remove_column :scripts, :template_script_type
  end
end
