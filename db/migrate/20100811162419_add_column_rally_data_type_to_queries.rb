################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnRallyDataTypeToQueries < ActiveRecord::Migration
  def self.up
    add_column :queries, :rally_data_type, :string
  end

  def self.down
    remove_column :queries, :rally_data_type
  end
end
