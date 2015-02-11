################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddApprovedSpendToBliAndTempBli < ActiveRecord::Migration
  def self.up
    add_column :temporary_budget_line_items, :approved_spend, :string
    add_column :budget_line_items, :approved_spend, :string
  end

  def self.down
    remove_column :temporary_budget_line_items, :approved_spend
    remove_column :budget_line_items, :approved_spend
  end
end
