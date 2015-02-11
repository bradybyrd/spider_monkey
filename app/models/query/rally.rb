################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Query < ActiveRecord::Base
  
  class << self
    # Add Release Contents 
    def create_query_and_details(plan, params, user, rally_data_type)
      query = Query.new(params[:query])
      query.plan_id = plan.id
      query.rally_data_type = rally_data_type
      query.tab_id = params[:tab_id]
      query.save

      for i in 0..(params[:query_detail][:query_element].size-1)
        query_detail = QueryDetail.create(:query_element => params[:query_detail][:query_element][i], 
                                          :query_term => params[:query_detail][:query_term][i],
                                          :query_criteria => params[:query_detail][:query_criteria][i],
                                          :query_id => query.id) unless params[:query_detail][:query_term][i].eql?('')
      end

      params[:release_content].each do |k, release_content|
        release_content.each do |k, contents|
          rc = ReleaseContent.find_or_create_by_formatted_i_d(contents)
          rc.query_id = query.try(:id)
          rc.plan_id = plan.id
          rc.tab_id = query.tab_id
          rc.save
        end
      end
    end

    # Add Build Contents
    def create_query_and_build_details(plan, params, user, rally_data_type)
      query = Query.new(params[:query])
      query.plan_id = plan.id
      query.rally_data_type = rally_data_type
      query.save
      # Create Query-details
      for i in 0..(params[:query_detail][:query_element].size-1)
        query_detail = QueryDetail.create(:query_element => params[:query_detail][:query_element][i], 
                                          :query_term => params[:query_detail][:query_term][i],
                                          :query_criteria => params[:query_detail][:query_criteria][i],
                                          :query_id => query.id) unless params[:query_detail][:query_term][i].eql?('')
      end
      # Create Build-Contents
      params[:build_content].each do |k, build_content|
        build_content.each do |k, contents|
          rc = BuildContent.find_or_create_by_object_i_d(contents)
          rc.query_id = query.try(:id)
          rc.plan_id = plan.id
          rc.save
        end
      end
    end

    # Update Release Contents 
    def update_release_query_and_details(plan, params, current_user, rally_data_type, query_id)
      query = self.find query_id
      params[:query].merge!(:last_run_at => Time.now, :tab_id => params[:tab_id])
      query.update_attributes(params[:query])


      query.query_details.destroy_all
      # Update Query-details
      if params[:query_detail]
        for i in 0..(params[:query_detail][:query_element].size-1)
          query_detail = QueryDetail.create(:query_element => params[:query_detail][:query_element][i], 
                                            :query_term => params[:query_detail][:query_term][i],
                                            :query_criteria => params[:query_detail][:query_criteria][i],
                                            :query_id => query.id) unless params[:query_detail][:query_term][i].eql?('')
        end
      end

      query.release_contents.destroy_all
      params[:release_content].each do |k, release_content|
        release_content.each do |k, contents|
          rc = ReleaseContent.find_or_create_by_formatted_i_d(contents)
          rc.query_id = query.try(:id)
          rc.tab_id = query.tab_id
          rc.plan_id = plan.id
          rc.save
        end
      end
    end

    # Update Build Contents
    def update_build_query_and_details(plan, params, user, rally_data_type, query_id)
      query = self.find query_id
      params[:query].merge!(:last_run_at => Time.now)
      query.update_attributes(params[:query])

      query.query_details.destroy_all
      # Create Query-details
      for i in 0..(params[:query_detail][:query_element].size-1)
        query_detail = QueryDetail.create(:query_element => params[:query_detail][:query_element][i], 
                                          :query_term => params[:query_detail][:query_term][i],
                                          :query_criteria => params[:query_detail][:query_criteria][i],
                                          :query_id => query.id) unless params[:query_detail][:query_term][i].eql?('')
      end

      query.build_contents.destroy_all
      # Create Build-Contents
      params[:build_content].each do |k, build_content|
        build_content.each do |k, contents|
          rc = BuildContent.find_or_create_by_object_i_d(contents)
          rc.query_id = query.try(:id)
          rc.plan_id = plan.id
          rc.save
        end
      end
    end
  end
  
end
