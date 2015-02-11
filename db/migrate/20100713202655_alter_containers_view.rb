################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AlterContainersView < ActiveRecord::Migration
  def self.up
    #### Disabled SmartPortfolio related code. It can be deleted after BRPM 2.5...
    if PortfolioSupport
      name = AdapterName == 'MySQL' ? "CONCAT(users.first_name, ' ', users.last_name)" : "users.first_name || ' ' || users.last_name"
      sql_or = AdapterName == 'MySQL' ? "OR" : "||"
    
      execute <<-SQL
    CREATE OR REPLACE VIEW containers_view (id, approved_spend, projected_cost, bottom_up_forecast, year_end_forecast, year_to_date_actual_spend, name, data_type, group_name, manager_name) AS
    SELECT containers.id, COALESCE(SUM(budget_line_items.approved_spend), 0), COALESCE(SUM(budget_line_items.projected_cost), 0), COALESCE(SUM(budget_line_items.bottom_up_forecast), 0), COALESCE(SUM(aggregate_blis_view.yef), 0), COALESCE(SUM(aggregate_blis_view.actuals), 0), containers.name,
    containers.container_type, groups.name, #{name} FROM containers
    INNER JOIN users ON users.id = containers.manager_id
    INNER JOIN groups ON groups.id = containers.group_id
    LEFT OUTER JOIN parent_activities ON parent_activities.container_id = containers.id
    LEFT OUTER JOIN budget_line_items ON budget_line_items.activity_id = parent_activities.activity_id
    LEFT OUTER JOIN aggregate_blis_view ON budget_line_items.id = aggregate_blis_view.budget_line_item_id
    WHERE budget_line_items.is_deleted = '0' OR budget_line_items.is_deleted IS NULL
    GROUP BY containers.id, containers.name, containers.container_type, groups.name, #{name}
      SQL
    end 
  end

  def self.down
    # tough luck!
  end
end
