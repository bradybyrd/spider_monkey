################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnHumanizedQueryInQueries < ActiveRecord::Migration
  def self.up
    add_column :queries, :humanized_query, :text
  end

  def self.down
    remove_column :queries, :humanized_query
  end
end
