################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnAasmStateToLifecycle < ActiveRecord::Migration
  def self.up
    add_column :lifecycles, :aasm_state, :string, :default => "created"
  end

  def self.down
    remove_column :lifecycles, :aasm_state
  end
end
