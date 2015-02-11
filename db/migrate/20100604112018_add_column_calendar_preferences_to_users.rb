################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnCalendarPreferencesToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :calendar_preferences, :text
  end

  def self.down
    remove_column :users, :calendar_preferences
  end
end
