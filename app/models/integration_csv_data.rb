################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class IntegrationCsvData < ActiveRecord::Base
  
  self.table_name = :integration_csv_data
  
  belongs_to :integration_csv_column
  
  validates :integration_csv_column_id, :presence => true
  
end
