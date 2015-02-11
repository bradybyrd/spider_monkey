################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Query < ActiveRecord::Base

  class << self

    def run_again!(query_details)
      running_equals(false).id_equals(query_details[:query_ids]).each do |query|
        query.update_attribute(:running, true)
      end
      # delay.execute!(query_details)
      execute!(query_details)
    end

    def execute!(query_details)
      running_equals(true).id_equals(query_details[:query_ids]).each do |query|
        change_requests = ServiceNow::Request.search({:value => query.query, :project_server_id => query.project_server_id}) || []
        [change_requests].flatten.each do |cr|
          change_request = ChangeRequest.find_or_create_by_sys_id(cr.sys_id) if cr.respond_to?(:sys_id)
          change_request.category = cr.respond_to?(:category) ? cr.category  : nil
          change_request.short_description = cr.respond_to?(:short_description) ? cr.short_description : nil
          change_request.plan_id = query_details[:plan_id]
          change_request.query_id = query.id
          change_request.tab_id = query_details[:tab_id]
          change_request.project_server_id = query.project_server_id
          change_request.sys_id = cr.respond_to?(:sys_id) ? cr.sys_id : nil
          change_request.approval = cr.respond_to?(:approval) ? cr.approval : nil
          change_request.start_date = cr.respond_to?(:start_date) ? cr.start_date : nil
          change_request.end_date = cr.respond_to?(:end_date) ? cr.end_date : nil
          change_request.cg_no = cr.respond_to?(:number) ?  cr.number : nil
          if change_request.new_record? 
            change_request.show_in_step = true
          end
          change_request.u_code_synch_required = cr.u_code_synch_required if cr.respond_to?(:u_code_synch_required)
          change_request.u_service_affecting = cr.u_service_affecting if cr.respond_to?(:u_service_affecting)
          change_request.u_application_name = cr.u_application_name if cr.respond_to?(:u_application_name)
          change_request.u_stage = cr.u_stage if cr.respond_to?(:u_stage)
          change_request.cr_state = cr.respond_to?(:state) ?  ProjectServer::ServiceNowStates[cr.state] : nil   
          change_request.cr_type = cr["type"] if cr.respond_to?(:type)
          change_request.save
        end
        query.last_run_by = query_details[:user_id]
        query.running = false
        query.save
      end
    end

  end

end

