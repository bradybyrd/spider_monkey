################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnUserIdToIntegrationCsvs < ActiveRecord::Migration
  def self.up
    add_column :integration_csvs, :user_id, :integer
  end

  def self.down
    remove_column :integration_csvs, :user_id
  end
end
