################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddingParentIdToTransactionLogs < ActiveRecord::Migration
  def self.up
    add_column :transaction_logs, :parent_id, :integer
  end

  def self.down
    remove_column :transaction_logs, :parent_id
  end
end
