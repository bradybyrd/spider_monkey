class RemovePortfolioViewsAndTables < ActiveRecord::Migration
  def self.up
    ["financials_view", "activities_view", "containers_view", "aggregate_financials_view", "aggregate_blis_view"].each do | view |
      if ActiveRecord::Base.connection.table_exists?(view) == true
        ActiveRecord::Base.connection.execute("drop view #{view}")
        puts "View #{view} dropped successfully"
      else
        puts "View #{view} does not exist. Skipping..."
      end
    end
  
    ["activities_collectors", "aggregate_financials", "bli_totals", "budget_import_logs", "budget_line_items",
      "containers", "export_import_sessions", "export_logs", "financials_collectors", "parent_activities",
      "temporary_budget_line_items", "portfolio_roadmaps", "chat_logs"].each do | t |
        if ActiveRecord::Base.connection.table_exists?(t) == true
          ActiveRecord::Base.connection.execute("drop table #{t}")
          puts "Table #{t} dropped successfully"
        else
          puts "Table #{t} does not exist. Skipping..."
        end
    end
    
  end

  def self.down
  end
end
