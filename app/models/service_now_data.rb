################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ServiceNowData < ActiveRecord::Base
  
  self.table_name = :service_now_data
  
  validates_presence_of :name,:presence => true
  validates_presence_of :project_server_id,:presence => true 
  validates :sys_id,:presence => true
  
  belongs_to :project_server
  
  scope :of_project_server, lambda { |project_server_id|
      select("service_now_data.sys_id, service_now_data.name").
      where("service_now_data.project_server_id" => project_server_id)
  }
  
  scope :name_equals, lambda {|names|
      select("service_now_data.sys_id, service_now_data.name").
      where("LOWER(service_now_data.name) IN (?)", Array(names).map(&:downcase))
  }
  
  scope :by_name_fragment, lambda {|name|
      select("service_now_data.sys_id, service_now_data.name").
      where("LOWER(service_now_data.name) LIKE ?", "%#{name.downcase}%")
  }
    
  scope :sys_ids_equals, lambda {|sys_ids|
      select("service_now_data.sys_id, service_now_data.name").
      where("service_now_data.sys_id IN (?)", sys_ids)
  }

  class << self
    def save_query(params)
      if params[:query][:id].present?
        query = Query.find(params[:query][:id])
        query.update_attributes(params[:query])
        query.query_details.destroy_all
      else
        query = Query.new(params[:query])
        query.save
      end
      params[:query_detail].each_pair { |key, query_detail|
        query.query_details.create(query_detail)
      }
      query
    end
  end
  
end
