################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AlterTableChatLogs < ActiveRecord::Migration
  def self.up
    if PostgreSQLAdapter || MySQLAdapter
      add_column :chat_logs, :content, :text
    elsif AdapterName == 'OracleEnhanced'
      ActiveRecord::Base.connection.execute("ALTER TABLE chat_logs ADD (content CLOB)")
    else
      add_column :chat_logs, :content, :text
    end
    add_column :chat_logs, :chat_date, :date
  end

  def self.down
    remove_column :chat_logs, :content
    remove_column :chat_logs, :chat_date
  end
end
