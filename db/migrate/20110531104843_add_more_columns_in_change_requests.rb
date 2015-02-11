################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddMoreColumnsInChangeRequests < ActiveRecord::Migration
  def self.up
    add_column :change_requests, :u_pmo_project_id, :string
    add_column :change_requests, :u_cc_environment, :string
    add_column :change_requests, :assignment_group, :string
    add_column :change_requests, :risk, :string
  end

  def self.down
    remove_column :change_requests, :u_pmo_project_id
    remove_column :change_requests, :u_cc_environment
    remove_column :change_requests, :assignment_group
    remove_column :change_requests, :risk
  end
end
