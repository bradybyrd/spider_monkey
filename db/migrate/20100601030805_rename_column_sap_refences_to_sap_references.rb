################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class RenameColumnSapRefencesToSapReferences < ActiveRecord::Migration
  def self.up
    rename_column :budget_line_items, :sap_refences, :sap_references
    rename_column :temporary_budget_line_items, :sap_refences, :sap_references
  end

  def self.down
    rename_column :budget_line_items, :sap_references, :sap_refences
    rename_column :temporary_budget_line_items, :sap_references, :sap_refences
  end
end
