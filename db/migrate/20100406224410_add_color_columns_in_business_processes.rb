################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColorColumnsInBusinessProcesses < ActiveRecord::Migration
  def self.up
    add_column :business_processes, :label_color, :string
  end

  def self.down
    remove_column :business_processes, :label_color
  end
end
