################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddPoFieldsToTemporaryBli < ActiveRecord::Migration
  def self.up
    add_column :temporary_budget_line_items, :po_yef_2010, :integer
    add_column :temporary_budget_line_items, :po_fcst_jan_2010, :integer
    add_column :temporary_budget_line_items, :po_fcst_feb_2010, :integer
    add_column :temporary_budget_line_items, :po_fcst_mar_2010, :integer
    add_column :temporary_budget_line_items, :po_fcst_apr_2010, :integer
    add_column :temporary_budget_line_items, :po_fcst_may_2010, :integer
    add_column :temporary_budget_line_items, :po_fcst_jun_2010, :integer
    add_column :temporary_budget_line_items, :po_fcst_jul_2010, :integer
    add_column :temporary_budget_line_items, :po_fcst_aug_2010, :integer
    add_column :temporary_budget_line_items, :po_fcst_sep_2010, :integer
    add_column :temporary_budget_line_items, :po_fcst_oct_2010, :integer
    add_column :temporary_budget_line_items, :po_fcst_nov_2010, :integer
    add_column :temporary_budget_line_items, :po_fcst_dec_2010, :integer
  end

  def self.down
    remove_column :temporary_budget_line_items, :po_yef_2010
    remove_column :temporary_budget_line_items, :po_fcst_jan_2010
    remove_column :temporary_budget_line_items, :po_fcst_feb_2010
    remove_column :temporary_budget_line_items, :po_fcst_mar_2010
    remove_column :temporary_budget_line_items, :po_fcst_apr_2010
    remove_column :temporary_budget_line_items, :po_fcst_may_2010
    remove_column :temporary_budget_line_items, :po_fcst_jun_2010
    remove_column :temporary_budget_line_items, :po_fcst_jul_2010
    remove_column :temporary_budget_line_items, :po_fcst_aug_2010
    remove_column :temporary_budget_line_items, :po_fcst_sep_2010
    remove_column :temporary_budget_line_items, :po_fcst_oct_2010
    remove_column :temporary_budget_line_items, :po_fcst_nov_2010
    remove_column :temporary_budget_line_items, :po_fcst_dec_2010
  end
end
