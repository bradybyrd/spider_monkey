################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ChangeCarNumberAndResponsibleCostCenterToString < ActiveRecord::Migration
  def self.up
    change_column :budget_line_items, :car_number, :string
    change_column :budget_line_items, :responsible_cost_center, :string
    change_column :temporary_budget_line_items, :car_number, :string
    change_column :temporary_budget_line_items, :responsible_cost_center, :string
  end

  def self.down
    change_column :budget_line_items, :car_number, :integer
    change_column :budget_line_items, :responsible_cost_center, :integer
    change_column :temporary_budget_line_items, :car_number, :integer
    change_column :temporary_budget_line_items, :responsible_cost_center, :integer
  end
end
