################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnLastResponseAtInUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :last_response_at, :datetime
  end

  def self.down
    remove_column :users, :last_response_at
  end
end
