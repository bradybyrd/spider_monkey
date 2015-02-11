################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateScriptArguments < ActiveRecord::Migration
  def self.up
    create_table :script_arguments, :force => true do |t|
      t.integer  :script_id
      t.string   :argument
      t.string   :name
      t.boolean  :is_private
      t.timestamps
    end
  end

  def self.down
    drop_table :script_arguments
  end
end
