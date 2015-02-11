################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreatePreferences < ActiveRecord::Migration
  def self.up
    create_table :preferences do |t|
      t.integer :user_id
      t.string  :text
      t.integer :position
      t.boolean :active, :default => true
      t.string  :preference_type, :string, :default => "Request"
      t.timestamps
    end
  end

  def self.down
    drop_table :preferences
  end
end
