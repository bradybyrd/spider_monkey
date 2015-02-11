################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateChatLogs < ActiveRecord::Migration
  def self.up
    create_table :chat_logs do |t|
      t.integer :sender_id
      t.integer :receiver_id
      t.timestamps
    end
  end

  def self.down
    drop_table :chat_logs
  end
end
