################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class FusionChart

  def volume_report(filters, requests_from_data)
    @filters = filters || {}
    data = []
    applications = application_in_report
    @columns_to_select = "requests.aasm_state"
    all_req_ids = requests_from_data.select("requests.id")
    completed_requests = refectored_requests(all_req_ids, "complete", "app_id") #requests(requests_from_data, "complete", "app_id")
    cancelled_requests = refectored_requests(all_req_ids, "cancelled","app_id")#requests(requests_from_data, "cancelled","app_id")
    problem_request = refectored_requests(all_req_ids, "problem", "app_id")#requests(requests_from_data, "problem", "app_id")
    hold_request = refectored_requests(all_req_ids, "hold", "app_id")#requests(requests_from_data, "hold", "app_id")
    @requests = nil
    applications.each do |app|
      data << {
                "Applications" => app.name,
                "Completed" => (completed_requests[app.id] || []).uniq.size,
                "Problem" => (problem_request[app.id] || []).uniq.size,
                "Hold" => (hold_request[app.id] || []).uniq.size,
                "Cancelled" => (cancelled_requests[app.id] || [] ).uniq.size,
                "Completed_request_url" => "j-displayRequests([#{request_ids(completed_requests[app.id])}])",
                "Problem_request_url" => "j-displayRequests([#{request_ids(problem_request[app.id])}])",
                "Hold_request_url" => "j-displayRequests([#{request_ids(hold_request[app.id])}])",
                "Cancelled_request_url" => "j-displayRequests([#{request_ids(cancelled_requests[app.id])}])"
            } 
      data.last.merge!({"total_request" => data.last["Completed"] + data.last["Problem"] + data.last["Hold"] + data.last["Cancelled"]})        
     end
     data = data.sort_by {|hsh| hsh["total_request"]}.reverse  
  end


  def request_ids(requests)
    (requests || []).map(&:id).join(',') 
  end
    
  def application_in_report
    if @filters[:app_id].present?
      App.find(filters[:app_id])
    else
      User.current_user.accessible_apps
    end  
  end 
end


