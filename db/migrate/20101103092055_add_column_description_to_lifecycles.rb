################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnDescriptionToLifecycles < ActiveRecord::Migration
  def self.up
    add_column :lifecycles, :description, :text
  end

  def self.down
    remove_column :lifecycles, :description
  end
end
