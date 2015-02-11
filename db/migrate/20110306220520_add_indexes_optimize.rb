################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddIndexesOptimize < ActiveRecord::Migration
  def self.up
    add_index :step_script_arguments, [:step_id, :script_argument_id], :name => 'script_arguments_by_step'
    add_index :notes, :step_id, :name => 'notes_by_step'
    add_index :installed_components, [:application_component_id, :application_environment_id], :name => "ic_ac_ae_id"
    add_index :steps, :script_id, :name => "scripts_by_step"
    add_index :requests, :app_id, :name => "apps_by_request"
  end

  def self.down
    # la di da
  end
end
