################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class Step < ActiveRecord::Base

  # Save operation ticket to different integrations

  def save_operation_ticket(ticket_attributes)
    return self if ticket_attributes.blank?
    @ticket_attributes = ticket_attributes
    if ticket_attributes[:save_remotely].present? && ticket_attributes[:save_remotely] == "0"
      return ChangeRequest.save_locally(ticket_attributes, self)
    end
    if ticket_attributes[:id].present?
      cg = ChangeRequest.find(ticket_attributes[:id])
      unless cg.blank?
        unless cg.sys_id.blank?
          ticket_attributes[:operation] = "update"
          ticket_attributes[:sys_id] = cg.sys_id
        else
          ticket_attributes[:operation] = "insert"
        end
        ticket_attributes[:state] = ticket_attributes[:cr_state]
        ticket_attributes[:project_server_id] = cg.project_server_id
        ticket_attributes = ticket_attributes.delete_if{|k,v| k == :cg_no}
        ticket_attributes = ticket_attributes.delete_if{|k,v| v.blank?}
      end
    end

    @project_server_id = ticket_attributes[:project_server_id]
    ticket_attributes[:type] = ticket_attributes[:cr_type]
    ticket_attributes[:u_application] = ServiceNowData.find_by_name(ticket_attributes[:u_application_name]).try(:sys_id) || nil
    @sys_id = ServiceNow::Request.save(ticket_attributes) # returns sys_id
    save_remote_changes!
  end

  def save_remote_changes!
    cg = ChangeRequest.find_or_create_by_sys_id(@sys_id)
    cg.plan_id = request.plan_member.plan_id if request.present? && request.plan_member
    cg.project_server_id = @project_server_id
    # Promoting SNOW operation tickets where request is not used
    if request.blank?
      cg.tab_id = @ticket_attributes[:tab_id]
      cg.show_in_step = @ticket_attributes[:show_in_step]
      cg.plan_id = @ticket_attributes[:plan_id]
      cg.query_id = @ticket_attributes[:query_id]
    else
      cg.tab_id = 2 # From Plan::TABS. It is always 2 for Operations Tickets
      cg.show_in_step = true
    end
    cg.save
    cg.refresh!

    unless find_operation_ticket_steps.blank?
      Step.update_all("change_request_id = #{cg.id}", "id IN ( #{find_operation_ticket_steps.join(', ')})")
      reload unless new_record?
    end
    if request.present?
      step_holders = StepHolder.find_all_by_request_id(request.id)
      step_holders.each { |sh| sh.destroy }
    else
      crs = ChangeRequest.find_all_by_sys_id(@sys_id)
      crs.each{ |cr| cr.update_attributes(:cr_state => @ticket_attributes[:cr_state]) }
    end
    crs = ChangeRequest.find_all_by_sys_id(@sys_id)
    crs.each{ |cr| cr.update_attributes(:saved_remotely => true) }
    cg.reload
    cg.id
  end

  def service_now_apps
    request_app_names = request.apps.map {|a| a.name}
    if request_app_names.blank?
      []
    else
      change_request.project_server.service_now_apps.name_equals(request_app_names)
    end
  end

  def service_now_environments
    if request.environment_id.blank?
      []
    else
      change_request.project_server.service_now_environments.name_equals(environment_name)
    end
  end

  def service_now_servers
    if change_request_id.present?
      return [] if server_association_names.blank?
      change_request.project_server.service_now_servers.name_equals(server_association_names)
    else
      []
    end
  end

  def find_operation_ticket_steps
    steps = StepHolder.request_id_equals(request.id).map(&:step_id) if request.present?
  end

end
