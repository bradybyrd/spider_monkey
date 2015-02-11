################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddFrozenAppToAppsRequests < ActiveRecord::Migration
  def self.up
    add_column :apps_requests, :frozen_app, :binary
  end

  def self.down
    remove_column :apps_requests, :frozen_app
  end
end
