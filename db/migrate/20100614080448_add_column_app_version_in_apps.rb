################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnAppVersionInApps < ActiveRecord::Migration
  def self.up
    add_column :apps, :app_version, :string
  end

  def self.down
    remove_column :apps, :app_version
  end
end
