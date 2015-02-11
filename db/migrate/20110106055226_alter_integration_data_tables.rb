################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AlterIntegrationDataTables < ActiveRecord::Migration
  
  # TODO - Piyush - There are plans to allow user to define tabs on lifecycle page on his own.
  # So better keep tab_id For now Lifecycle::Tabs will hold their values which will then come from
  # some tables.
  # we may require more generic tables then. So even these tables will have to be removed except
  # integration_csvs
  
  def self.up
    add_column :release_contents, :tab_id, :integer, :default => 1
    add_column :release_content_items, :tab_id, :integer, :default => 1
    add_column :queries, :tab_id, :integer, :default => 1
    add_column :integration_csvs, :tab_id, :integer, :default => 1
  end

  def self.down
    remove_column :release_contents, :tab_id
    remove_column :release_content_items, :tab_id
    remove_column :queries, :tab_id
    remove_column :integration_csvs, :tab_id
  end
end
