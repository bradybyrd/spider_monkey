################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class IntegrationCsv < ActiveRecord::Base
        
  # TODO - Primary column concept can be removed Wait for new requirements
  attr_accessor :csv, :can_be_saved, :primary_column 
    
  validates :plan_id, :presence => true
  validates :project_server_id, :presence => true
  validates :name, :presence => true
  
  ContentTypes = ["application/vnd.ms-excel", "text/plain", "text/csv"]
  
  belongs_to :plan
  belongs_to :project_server
  belongs_to :user
  has_many :integration_csv_columns, :dependent => :destroy
  
  delegate :to_label, :to => :user,  :prefix => true, :allow_nil => true
  
  def validate
    unless !csv.blank? && ContentTypes.include?(csv.content_type)
      self.errors[:base] << "Please upload valid CSV file"
    end
    
    if can_be_saved == '1'
      self.errors[:base] << "Please select a primary column" if primary_column.blank?
    end
  end
  
  def parse!
    @csv_rows = CSV.read(csv.path, :headers => true)
  end
  
  def saved!
    can_be_saved == '1' && primary_column
  end
  
  def save_csv_data!
    if can_be_saved == '1' && primary_column
      csv = plan.integration_csvs.where(:tab_id => tab_id).first
      csv.destroy if csv
      save!
      save_csv_columns!
    end
  end
  
  def save_csv_columns! # columns are referred to CSV headers
    column_names.each do |col|
      integration_csv_columns.new(:name => col, :primary => primary_column.strip == col.strip).save(:validate => false)
    end
    save_csv_rows!
  end
  
  def save_csv_rows!
    integration_csv_columns.each do |csv_column|
      @csv_rows.each do |row|
       csv_column.integration_csv_data.new(:value => row[csv_column.name]).save(:validate => false)
      end
    end
  end
  
  def column_names
    @csv_rows.headers
  end
  
end
