################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnsToChangeRequests < ActiveRecord::Migration
    
  def self.up
    add_column :change_requests, :cg_no,              :string
    add_column :change_requests, :start_date,         :string
    add_column :change_requests, :end_date,           :string
    add_column :change_requests, :planned_start_date, :string
    add_column :change_requests, :planned_end_date,   :string
    add_column :change_requests, :approval,           :string

    if OracleAdapter
      connection.execute("ALTER TABLE change_requests ADD (description CLOB)") 
    elsif PostgreSQLAdapter || MySQLAdapter
      add_column :change_requests, :description, :text
    else
      add_column :change_requests, :description, :text
    end
    add_column :change_requests, :show_in_step,       :boolean, :default => false    
  end

  def self.down
    remove_column :change_requests, :cg_no
    remove_column :change_requests, :start_date
    remove_column :change_requests, :end_date
    remove_column :change_requests, :planned_start_date
    remove_column :change_requests, :planned_end_date
    remove_column :change_requests, :approval
    remove_column :change_requests, :description
    remove_column :change_requests, :show_in_step
  end
end
