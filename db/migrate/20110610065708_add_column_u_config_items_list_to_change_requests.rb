################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnUConfigItemsListToChangeRequests < ActiveRecord::Migration
  def self.up
    add_column :change_requests, :u_config_items_list, :string
  end

  def self.down
    remove_column :change_requests, :u_config_items_list
  end
end
