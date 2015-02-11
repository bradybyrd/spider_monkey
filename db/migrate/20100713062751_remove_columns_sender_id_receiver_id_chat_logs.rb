################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class RemoveColumnsSenderIdReceiverIdChatLogs < ActiveRecord::Migration
  def self.up
    remove_column :chat_logs, :sender_id
    remove_column :chat_logs, :receiver_id
    add_column :chat_logs, :user_ids, :text
  end

  def self.down
    add_column :chat_logs, :sender_id, :integer
    add_column :chat_logs, :receiver_id, :integer
    remove_column :chat_logs, :user_ids
  end
end
