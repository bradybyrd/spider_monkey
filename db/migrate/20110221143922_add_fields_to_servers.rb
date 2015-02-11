################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddFieldsToServers < ActiveRecord::Migration
  def self.up
    add_column :servers, :dns, :string
    add_column :servers, :ip_address, :string
    add_column :servers, :os_platform, :string    
  end

  def self.down
    remove_column :servers, :dns
    remove_column :servers, :ip_address
    remove_column :servers, :os_platform
    
  end
end
