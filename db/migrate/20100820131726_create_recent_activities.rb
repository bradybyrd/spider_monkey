################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateRecentActivities < ActiveRecord::Migration
  def self.up
    create_table :recent_activities do |t|
      t.string :verb, :null => false
      t.references :actor, :polymorphic => true
      t.references :object, :polymorphic => true
      t.references :indirect_object, :polymorphic => true
      t.string :context
      t.datetime :timestamp, :null => false
    end
  end

  def self.down
    drop_table :recent_activities
  end
end
