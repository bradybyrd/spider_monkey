################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateScripts < ActiveRecord::Migration
  def self.up
    create_table :scripts, :force => true do |t|
      t.string   :name
      t.string   :script_type
      t.string   :description
      t.text     :content
      t.integer  :integration_id
      t.timestamps
    end
  end

  def self.down
    drop_table :scripts
  end
end
