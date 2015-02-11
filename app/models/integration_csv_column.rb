################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class IntegrationCsvColumn < ActiveRecord::Base
  
  has_many :integration_csv_data, :class_name => "IntegrationCsvData", :dependent => :destroy
  belongs_to :integration_csv
  
  validates :name,
            :presence => true,
            :uniqueness => true
  
  
end
