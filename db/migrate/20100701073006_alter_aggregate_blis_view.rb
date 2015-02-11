################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AlterAggregateBlisView < ActiveRecord::Migration
  
  def self.up
    #### Disabled SmartPortfolio related code. It can be deleted after BRPM 2.5...
    if PortfolioSupport
      execute <<-SQL
    
    CREATE OR REPLACE VIEW aggregate_blis_view (activity_id, budget_line_item_id, yef, actuals) AS
    
    SELECT 
    
    activities.id,
    
    budget_line_items.id,
    
    COALESCE(budget_line_items.forecast_jan_2010, 0) + 
    COALESCE(budget_line_items.forecast_feb_2010, 0) + 
    COALESCE(budget_line_items.forecast_mar_2010, 0) + 
    COALESCE(budget_line_items.forecast_apr_2010, 0) + 
    COALESCE(budget_line_items.forecast_mei_2010, 0) +
    COALESCE(budget_line_items.forecast_jun_2010, 0) + 
    COALESCE(budget_line_items.forecast_jul_2010, 0) +
    COALESCE(budget_line_items.forecast_aug_2010, 0) + 
    COALESCE(budget_line_items.forecast_sep_2010, 0) + 
    COALESCE(budget_line_items.forecast_oct_2010, 0) + 
    COALESCE(budget_line_items.forecast_nov_2010, 0) + 
    COALESCE(budget_line_items.forecast_dec_2010, 0),
    
    COALESCE(budget_line_items.actuals_jan_2010, 0) + 
    COALESCE(budget_line_items.actuals_feb_2010, 0) + 
    COALESCE(budget_line_items.actuals_mar_2010, 0) + 
    COALESCE(budget_line_items.actuals_apr_2010, 0) + 
    COALESCE(budget_line_items.actuals_mei_2010, 0) +
    COALESCE(budget_line_items.actuals_jun_2010, 0) + 
    COALESCE(budget_line_items.actuals_jul_2010, 0) +
    COALESCE(budget_line_items.actuals_aug_2010, 0) + 
    COALESCE(budget_line_items.actuals_sep_2010, 0) + 
    COALESCE(budget_line_items.actuals_oct_2010, 0) + 
    COALESCE(budget_line_items.actuals_nov_2010, 0) + 
    COALESCE(budget_line_items.actuals_dec_2010, 0)
    
    FROM budget_line_items
    RIGHT OUTER JOIN activities ON budget_line_items.activity_id = activities.id
    
      SQL
    end
  end
  
  def self.down
    #### Disabled SmartPortfolio related code. It can be deleted after BRPM 2.5...
    if PortfolioSupport
      execute <<-SQL
    
    CREATE OR REPLACE VIEW aggregate_blis_view (budget_line_item_id, yef, actuals) AS
    
    SELECT 
    
    budget_line_items.id,
    
    COALESCE(budget_line_items.forecast_jan_2010, 0) + 
    COALESCE(budget_line_items.forecast_feb_2010, 0) + 
    COALESCE(budget_line_items.forecast_mar_2010, 0) + 
    COALESCE(budget_line_items.forecast_apr_2010, 0) + 
    COALESCE(budget_line_items.forecast_mei_2010, 0) +
    COALESCE(budget_line_items.forecast_jun_2010, 0) + 
    COALESCE(budget_line_items.forecast_jul_2010, 0) +
    COALESCE(budget_line_items.forecast_aug_2010, 0) + 
    COALESCE(budget_line_items.forecast_sep_2010, 0) + 
    COALESCE(budget_line_items.forecast_oct_2010, 0) + 
    COALESCE(budget_line_items.forecast_nov_2010, 0) + 
    COALESCE(budget_line_items.forecast_dec_2010, 0),
    
    COALESCE(budget_line_items.actuals_jan_2010, 0) + 
    COALESCE(budget_line_items.actuals_feb_2010, 0) + 
    COALESCE(budget_line_items.actuals_mar_2010, 0) + 
    COALESCE(budget_line_items.actuals_apr_2010, 0) + 
    COALESCE(budget_line_items.actuals_mei_2010, 0) +
    COALESCE(budget_line_items.actuals_jun_2010, 0) + 
    COALESCE(budget_line_items.actuals_jul_2010, 0) +
    COALESCE(budget_line_items.actuals_aug_2010, 0) + 
    COALESCE(budget_line_items.actuals_sep_2010, 0) + 
    COALESCE(budget_line_items.actuals_oct_2010, 0) + 
    COALESCE(budget_line_items.actuals_nov_2010, 0) + 
    COALESCE(budget_line_items.actuals_dec_2010, 0)
    
    FROM budget_line_items
      SQL
    end
  end

end
