################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class TransactionLog < ActiveRecord::Base
  #### Commented SmartPortfolio related code. It can be deleted after BRPM 2.5...
  if PortfolioSupport 
    serialize :content, Hash
    serialize :content_long, Hash
    serialize :content_text, Hash
  end
end

class ChangeTrxLogContentToLongtext < ActiveRecord::Migration
  def self.up
    #### Commented SmartPortfolio related code. It can be deleted after BRPM 2.5...
    if PortfolioSupport
      if OracleAdapter
        unless TransactionLog.column_names.include?('content_long')
          TransactionLog.connection.execute("ALTER TABLE transaction_logs ADD (content_long CLOB)")
        end
        say_with_time "Changing content column to long" do
          TransactionLog.all.each do |tl|
            tl.update_attribute(:content_long, tl.content)
          end
        end
        remove_column :transaction_logs, :content
        rename_column :transaction_logs, :content_long, :content
      else
        change_column :transaction_logs, :content, :longtext
      end
    end
  end

  def self.down
    #### Commented SmartPortfolio related code. It can be deleted after BRPM 2.5...
    if PortfolioSupport
      if OracleAdapter
        add_column :transaction_logs, :content_text, :text unless TransactionLog.column_names.include?('content_text')
        say_with_time "Changing content column to text" do
          TransactionLog.all.each do |tl|
            tl.update_attribute(:content_text, tl.content)
          end
        end
        remove_column :transaction_logs, :content
        rename_column :transaction_logs, :content_text, :content
      else
        change_column :transaction_logs, :content, :text
      end
    end
  end
  
end
