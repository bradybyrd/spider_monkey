################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnFirstTimeLoginAndIsResetPasswordToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :first_time_login, :boolean, :default => true
    add_column :users, :is_reset_password, :boolean, :default => false
  end

  def self.down
    remove_column :users, :first_time_login
    remove_column :users, :is_reset_password
  end
end
