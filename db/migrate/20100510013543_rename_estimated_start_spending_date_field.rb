################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class RenameEstimatedStartSpendingDateField < ActiveRecord::Migration
  def self.up
    rename_column :budget_line_items, :estimated_start_spending, :estimated_start_for_spend
    rename_column :temporary_budget_line_items, :estimated_start_spending, :estimated_start_for_spend
  end

  def self.down
    rename_column :budget_line_items, :estimated_start_for_spend, :estimated_start_spending
    rename_column :temporary_budget_line_items, :estimated_start_for_spend, :estimated_start_spending
  end
end
