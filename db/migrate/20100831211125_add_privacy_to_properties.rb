################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddPrivacyToProperties < ActiveRecord::Migration
  def self.up
    add_column :capistrano_script_arguments, :is_private, :boolean
    add_column :bladelogic_script_arguments, :is_private, :boolean
    add_column :properties, :is_private, :boolean
  end

  def self.down
    remove_column :capistrano_script_arguments, :is_private
    remove_column :bladelogic_script_arguments, :is_private
    remove_column :properties, :is_private
  end
end
