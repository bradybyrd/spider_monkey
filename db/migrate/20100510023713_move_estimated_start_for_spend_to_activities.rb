################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class MoveEstimatedStartForSpendToActivities < ActiveRecord::Migration
  def self.up
    remove_column :budget_line_items, :estimated_start_for_spend
    remove_column :temporary_budget_line_items, :estimated_start_for_spend
    add_column :activities, :estimated_start_for_spend, :datetime
  end

  def self.down
    remove_column :activities, :estimated_start_for_spend
    add_column :budget_line_items, :estimated_start_for_spend, :datetime
    add_column :temporary_budget_line_items, :estimated_start_for_spend, :datetime
  end
end
