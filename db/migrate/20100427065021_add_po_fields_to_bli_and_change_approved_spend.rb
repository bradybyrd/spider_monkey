################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class BudgetLineItem < ActiveRecord::Base
end

class AddPoFieldsToBliAndChangeApprovedSpend < ActiveRecord::Migration
  def self.up
    #### Commented SmartPortfolio related code. It can be deleted after BRPM 2.5...
    if PortfolioSupport
      if AdapterName == 'OracleEnhanced'
        rename_column :budget_line_items, :integer, :approved_spend if BudgetLineItem.column_names.include?('integer')
        add_column :budget_line_items, :approved_spend_int, :integer unless BudgetLineItem.column_names.include?('approved_spend_int')
        say_with_time "Changing approved_spend column to Integer" do
          BudgetLineItem.all.each do |bli|
            bli.update_attribute(:approved_spend_int, 1000) #bli.year.try(:to_i))
          end
        end
        remove_column :budget_line_items, :approved_spend
        rename_column :budget_line_items, :approved_spend_int, :approved_spend
      else
        change_column :budget_line_items, :approved_spend, :integer
      end
    
      add_column :budget_line_items, :po_yef_2010, :integer
      add_column :budget_line_items, :po_fcst_jan_2010, :integer
      add_column :budget_line_items, :po_fcst_feb_2010, :integer
      add_column :budget_line_items, :po_fcst_mar_2010, :integer
      add_column :budget_line_items, :po_fcst_apr_2010, :integer
      add_column :budget_line_items, :po_fcst_may_2010, :integer
      add_column :budget_line_items, :po_fcst_jun_2010, :integer
      add_column :budget_line_items, :po_fcst_jul_2010, :integer
      add_column :budget_line_items, :po_fcst_aug_2010, :integer
      add_column :budget_line_items, :po_fcst_sep_2010, :integer
      add_column :budget_line_items, :po_fcst_oct_2010, :integer
      add_column :budget_line_items, :po_fcst_nov_2010, :integer
      add_column :budget_line_items, :po_fcst_dec_2010, :integer
    end
  end

  def self.down
    #### Commented SmartPortfolio related code. It can be deleted after BRPM 2.5...
    if PortfolioSupport
      if AdapterName == 'OracleEnhanced'
        add_column :budget_line_items, :approved_spend_string, :integer
        say_with_time "Reverting approved_spend column to String" do
          BudgetLineItem.all.each do |bli|
            bli.update_attribute(:approved_spend_year, bli.year)
          end
        end
        remove_column :budget_line_items, :approved_spend
        rename_column :budget_line_items, :approved_spend_string, :approved_spend
      else
        change_column :budget_line_items, :approved_spend, :string
      end
    
      remove_column :budget_line_items, :po_yef_2010
      remove_column :budget_line_items, :po_fcst_jan_2010
      remove_column :budget_line_items, :po_fcst_feb_2010
      remove_column :budget_line_items, :po_fcst_mar_2010
      remove_column :budget_line_items, :po_fcst_apr_2010
      remove_column :budget_line_items, :po_fcst_may_2010
      remove_column :budget_line_items, :po_fcst_jun_2010
      remove_column :budget_line_items, :po_fcst_jul_2010
      remove_column :budget_line_items, :po_fcst_aug_2010
      remove_column :budget_line_items, :po_fcst_sep_2010
      remove_column :budget_line_items, :po_fcst_oct_2010
      remove_column :budget_line_items, :po_fcst_nov_2010
      remove_column :budget_line_items, :po_fcst_dec_2010
    end
  end
end
