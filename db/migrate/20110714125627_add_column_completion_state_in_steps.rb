################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnCompletionStateInSteps < ActiveRecord::Migration
  def self.up
    add_column :steps, :completion_state, :string
  end

  def self.down
    remove_column :steps, :completion_state
  end
end
