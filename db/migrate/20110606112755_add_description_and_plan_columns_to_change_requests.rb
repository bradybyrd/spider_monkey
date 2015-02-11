################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddDescriptionAndPlanColumnsToChangeRequests < ActiveRecord::Migration
  def self.up
    if PostgreSQLAdapter || MySQLAdapter
      add_column :change_requests, :change_plan,  :text
      add_column :change_requests, :backout_plan, :text
      add_column :change_requests, :test_plan,    :text
    elsif OracleAdapter
      connection.execute("ALTER TABLE change_requests ADD (change_plan CLOB)") 
      connection.execute("ALTER TABLE change_requests ADD (backout_plan CLOB)") 
      connection.execute("ALTER TABLE change_requests ADD (test_plan CLOB)") 
    else
      add_column :change_requests, :change_plan,  :text
      add_column :change_requests, :backout_plan, :text
      add_column :change_requests, :test_plan,    :text
    end
  end

  def self.down
    remove_column :change_requests, :backout_plan
    remove_column :change_requests, :change_plan
    remove_column :change_requests, :test_plan
  end
end
