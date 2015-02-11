################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class TransactionLog < ActiveRecord::Base
  has_one :upload, :as => :owner
  serialize :logs
  serialize :content, Hash
  
  class << self
    
    def grouped_by_id_and_year
      if OracleAdapter  
        find(find_by_sql('SELECT id, year FROM transaction_logs GROUP BY id, year').map(&:id))
      else
        find(:all, :group => 'id, year')
      end
    end
    
  end
  
  def logs
    read_attribute("log_data")
  end

  def build_logs(log_key, log_data)
    self.logs = {}
    log_key.each_with_index do |k,i|
      self.logs[k] = log_data[i]
    end
  end

end
