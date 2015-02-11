################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################


class AddBudgetYearInLists < ActiveRecord::Migration
  def self.up
    add_column(:list_items, :is_active, :boolean, :default => true) unless ListItem.column_names.include?("is_active")

     if PostgreSQLAdapter
      ListItem.update_all ["is_active = ?", true]
    end

  end

  def self.down
    remove_column :list_items, :is_active
    # Doesn't matter if not rolled back
  end
end
