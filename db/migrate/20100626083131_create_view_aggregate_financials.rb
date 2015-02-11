################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateViewAggregateFinancials < ActiveRecord::Migration
  def self.up
    #### Disabled SmartPortfolio related code. It can be deleted after BRPM 2.5...
    if PortfolioSupport
      # This view will contain sum of costs of activities.
    
      execute <<-SQL
    CREATE OR REPLACE VIEW aggregate_financials_view
      (total_containers, container_id, container_name, container_approved_spend, container_projected_cost, container_bottom_up_forecast, 
      container_year_end_forecast, c_yr_to_date_actual_spend, container_type,
      container_group_name, container_manager_name, 
      activities_projected_cost, activities_bottom_up_forecast, 
      activities_year_end_forecast, as_yr_to_date_actual_spend) AS
      
    SELECT COUNT(financials_view.container_id), container_id, container_name, container_approved_spend, container_projected_cost, container_bottom_up_forecast, 
      container_year_end_forecast, c_yr_to_date_actual_spend, container_type, 
      container_group_name, container_manager_name,
      SUM(activity_projected_cost), SUM(activity_bottom_up_forecast), 
      SUM(activity_year_end_forecast),
      SUM(a_yr_to_date_actual_spend) FROM financials_view  
       
    GROUP BY container_id, container_name, container_approved_spend, container_projected_cost, container_bottom_up_forecast, 
      container_year_end_forecast, c_yr_to_date_actual_spend, container_type, container_group_name, 
      container_manager_name
      
    ORDER BY container_name
    
      SQL
    end
  end

  def self.down
    #### Disabled SmartPortfolio related code. It can be deleted after BRPM 2.5...
    if PortfolioSupport
      execute "DROP VIEW aggregate_financials_view"
    end
  end
end
