################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AlterActivitiesViews < ActiveRecord::Migration
  # This migration was added because activities_view written was not selecting activities
  # who do not have associated parent_activity. So INNER JOIN is changed to LEFT OUTER JOIN
  
  def self.up
    #### Disabled SmartPortfolio related code. It can be deleted after BRPM 2.5...
    if PortfolioSupport
      name = AdapterName == 'MySQL' ? "CONCAT(users.first_name, ' ', users.last_name)" : "users.first_name || ' ' || users.last_name"
    
      execute <<-SQL
    CREATE OR REPLACE VIEW containers_view (id, approved_spend, projected_cost, bottom_up_forecast, year_end_forecast, year_to_date_actual_spend, name, data_type, group_name, manager_name) AS
    SELECT containers.id, COALESCE(SUM(budget_line_items.approved_spend), 0), COALESCE(SUM(budget_line_items.projected_cost), 0), COALESCE(SUM(budget_line_items.bottom_up_forecast), 0), COALESCE(SUM(aggregate_blis_view.yef), 0), COALESCE(SUM(aggregate_blis_view.actuals), 0), containers.name,
    containers.container_type, groups.name, #{name} FROM containers
    INNER JOIN users ON users.id = containers.manager_id
    INNER JOIN groups ON groups.id = containers.group_id
    LEFT OUTER JOIN parent_activities ON parent_activities.container_id = containers.id
    LEFT OUTER JOIN budget_line_items ON budget_line_items.activity_id = parent_activities.activity_id
    LEFT OUTER JOIN aggregate_blis_view ON budget_line_items.id = aggregate_blis_view.budget_line_item_id
    WHERE budget_line_items.is_deleted = '0'
    GROUP BY containers.id, containers.name, containers.container_type, groups.name, #{name}
      SQL
        
      execute <<-SQL
    CREATE OR REPLACE VIEW activities_view (id, approved_spend, projected_cost, bottom_up_forecast, year_end_forecast, year_to_date_actual_spend, name, data_type, group_name, budget_category, manager_name, container_id, status,
    health, cio_list, estimated_start_for_spend) AS
    SELECT activities.id, COALESCE(SUM(budget_line_items.approved_spend), 0), COALESCE(SUM(budget_line_items.projected_cost), 0), COALESCE(SUM(budget_line_items.bottom_up_forecast), 0), COALESCE(SUM(aggregate_blis_view.yef), 0), COALESCE(SUM(aggregate_blis_view.actuals), 0), activities.name,
    activity_categories.name, groups.name, activities.budget_category,
    #{name}, parent_activities.container_id, activities.status, activities.health, activities.cio_list, activities.estimated_start_for_spend FROM activities
    
    INNER JOIN activity_categories ON activity_categories.id = activities.activity_category_id
    LEFT OUTER JOIN parent_activities ON parent_activities.activity_id = activities.id
    LEFT OUTER JOIN users ON users.id = activities.manager_id
    LEFT OUTER JOIN groups ON groups.id = activities.leading_group_id
    LEFT OUTER JOIN budget_line_items ON budget_line_items.activity_id = activities.id
    LEFT OUTER JOIN aggregate_blis_view ON budget_line_items.id = aggregate_blis_view.budget_line_item_id
    
    WHERE budget_line_items.is_deleted = '0' OR budget_line_items.is_deleted IS NULL
    
    GROUP BY activities.id, activities.name, activity_categories.name, groups.name,
    activities.budget_category, #{name},
    parent_activities.container_id, activities.status, activities.health, activities.cio_list, activities.estimated_start_for_spend
      SQL
    
    
      # container_year_to_date_actual_spend => c_yr_to_date_actual_spend
      # activity_year_to_date_actual_spend => a_yr_to_date_actual_spend
      execute <<-SQL
    CREATE OR REPLACE VIEW financials_view
    (container_id, container_name, container_approved_spend, container_projected_cost, container_bottom_up_forecast, container_year_end_forecast, c_yr_to_date_actual_spend, container_type,
    container_group_name, container_manager_name, activity_id, activity_name, activity_projected_cost, activity_bottom_up_forecast, activity_year_end_forecast, a_yr_to_date_actual_spend,
    activity_type, activity_group_name, activity_budget_category, activity_manager_name) AS
    
    SELECT containers_view.id, containers_view.name, containers_view.approved_spend, containers_view.projected_cost, containers_view.bottom_up_forecast, containers_view.year_end_forecast, containers_view.year_to_date_actual_spend, containers_view.data_type,
    containers_view.group_name, containers_view.manager_name, activities_view.id, activities_view.name,
    activities_view.projected_cost, activities_view.bottom_up_forecast, activities_view.year_end_forecast, activities_view.year_to_date_actual_spend, activities_view.data_type, activities_view.group_name,
    activities_view.budget_category, activities_view.manager_name FROM containers_view
    
    INNER JOIN activities_view ON activities_view.container_id = containers_view.id
    GROUP BY containers_view.id, containers_view.name, containers_view.approved_spend, containers_view.projected_cost,
    containers_view.bottom_up_forecast, containers_view.year_end_forecast,
    containers_view.year_to_date_actual_spend, containers_view.data_type,
    containers_view.group_name, containers_view.manager_name, activities_view.id, activities_view.name,
    activities_view.projected_cost, activities_view.bottom_up_forecast,
    activities_view.year_end_forecast, activities_view.year_to_date_actual_spend,
    activities_view.data_type, activities_view.group_name,
    activities_view.budget_category, activities_view.manager_name
      SQL
    end 
  end
  
  # This migration was added because activities_view and containers_view written were not selecting activities
  # who do not have any budget_line_items
  
  def self.down
    #### Disabled SmartPortfolio related code. It can be deleted after BRPM 2.5...
    if PortfolioSupport
      name = AdapterName == 'MySQL' ? "CONCAT(users.first_name, ' ', users.last_name)" : "users.first_name || ' ' || users.last_name"
    
      execute <<-SQL
    CREATE OR REPLACE VIEW containers_view (id, approved_spend, projected_cost, bottom_up_forecast, year_end_forecast, year_to_date_actual_spend, name, data_type, group_name, manager_name) AS
    SELECT containers.id, COALESCE(SUM(budget_line_items.approved_spend), 0), COALESCE(SUM(budget_line_items.projected_cost), 0), COALESCE(SUM(budget_line_items.bottom_up_forecast), 0), COALESCE(SUM(aggregate_blis_view.yef), 0), COALESCE(SUM(aggregate_blis_view.actuals), 0), containers.name,
    containers.container_type, groups.name, #{name} FROM containers
    INNER JOIN users ON users.id = containers.manager_id
    INNER JOIN groups ON groups.id = containers.group_id
    LEFT OUTER JOIN parent_activities ON parent_activities.container_id = containers.id
    LEFT OUTER JOIN budget_line_items ON budget_line_items.activity_id = parent_activities.activity_id
    LEFT OUTER JOIN aggregate_blis_view ON budget_line_items.id = aggregate_blis_view.budget_line_item_id
    WHERE budget_line_items.is_deleted = '0'
    GROUP BY containers.id, containers.name, containers.container_type, groups.name, #{name}
      SQL
        
      execute <<-SQL
    CREATE OR REPLACE VIEW activities_view (id, approved_spend, projected_cost, bottom_up_forecast, year_end_forecast, year_to_date_actual_spend, name, data_type, group_name, budget_category, manager_name, container_id, status,
    health, cio_list, estimated_start_for_spend) AS
    SELECT activities.id, COALESCE(SUM(budget_line_items.approved_spend), 0), COALESCE(SUM(budget_line_items.projected_cost), 0), COALESCE(SUM(budget_line_items.bottom_up_forecast), 0), COALESCE(SUM(aggregate_blis_view.yef), 0), COALESCE(SUM(aggregate_blis_view.actuals), 0), activities.name,
    activity_categories.name, groups.name, activities.budget_category,
    #{name}, parent_activities.container_id, activities.status, activities.health, activities.cio_list, activities.estimated_start_for_spend FROM activities
    
    INNER JOIN activity_categories ON activity_categories.id = activities.activity_category_id
    INNER JOIN parent_activities ON parent_activities.activity_id = activities.id
    LEFT OUTER JOIN users ON users.id = activities.manager_id
    LEFT OUTER JOIN groups ON groups.id = activities.leading_group_id
    LEFT OUTER JOIN budget_line_items ON budget_line_items.activity_id = activities.id
    LEFT OUTER JOIN aggregate_blis_view ON budget_line_items.id = aggregate_blis_view.budget_line_item_id
    
    WHERE budget_line_items.is_deleted = '0' OR budget_line_items.is_deleted IS NULL
    
    GROUP BY activities.id, activities.name, activity_categories.name, groups.name,
    activities.budget_category, #{name},
    parent_activities.container_id, activities.status, activities.health, activities.cio_list, activities.estimated_start_for_spend
      SQL
    
    
      # container_year_to_date_actual_spend => c_yr_to_date_actual_spend
      # activity_year_to_date_actual_spend => a_yr_to_date_actual_spend
      execute <<-SQL
    CREATE OR REPLACE VIEW financials_view
    (container_id, container_name, container_approved_spend, container_projected_cost, container_bottom_up_forecast, container_year_end_forecast, c_yr_to_date_actual_spend, container_type,
    container_group_name, container_manager_name, activity_id, activity_name, activity_projected_cost, activity_bottom_up_forecast, activity_year_end_forecast, a_yr_to_date_actual_spend,
    activity_type, activity_group_name, activity_budget_category, activity_manager_name) AS
    
    SELECT containers_view.id, containers_view.name, containers_view.approved_spend, containers_view.projected_cost, containers_view.bottom_up_forecast, containers_view.year_end_forecast, containers_view.year_to_date_actual_spend, containers_view.data_type,
    containers_view.group_name, containers_view.manager_name, activities_view.id, activities_view.name,
    activities_view.projected_cost, activities_view.bottom_up_forecast, activities_view.year_end_forecast, activities_view.year_to_date_actual_spend, activities_view.data_type, activities_view.group_name,
    activities_view.budget_category, activities_view.manager_name FROM containers_view
    
    INNER JOIN activities_view ON activities_view.container_id = containers_view.id
    GROUP BY containers_view.id, containers_view.name, containers_view.approved_spend, containers_view.projected_cost,
    containers_view.bottom_up_forecast, containers_view.year_end_forecast,
    containers_view.year_to_date_actual_spend, containers_view.data_type,
    containers_view.group_name, containers_view.manager_name, activities_view.id, activities_view.name,
    activities_view.projected_cost, activities_view.bottom_up_forecast,
    activities_view.year_end_forecast, activities_view.year_to_date_actual_spend,
    activities_view.data_type, activities_view.group_name,
    activities_view.budget_category, activities_view.manager_name
      SQL
    end 
  end
end
