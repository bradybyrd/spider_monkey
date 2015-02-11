################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AlterTableChangeRequests < ActiveRecord::Migration
  def self.up
    remove_column :change_requests, :assigned_to
    remove_column :change_requests, :expected_start
    remove_column :change_requests, :location
    remove_column :change_requests, :due_date
    add_column    :change_requests, :category, :string
  end

  def self.down
    add_column    :change_requests, :assigned_to, :string
    add_column    :change_requests, :expected_start, :string
    add_column    :change_requests, :location, :string
    add_column    :change_requests, :due_date, :string
    remove_column :change_requests, :category
  end
end
