################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddEstimatedFieldToBliAndTemporary < ActiveRecord::Migration
  def self.up
    add_column :budget_line_items, :estimated_start_spending, :datetime
    add_column :temporary_budget_line_items, :estimated_start_spending, :datetime
  end

  def self.down
    remove_column :budget_line_items, :estimated_start_spending
    remove_column :temporary_budget_line_items, :estimated_start_spending
  end
end
