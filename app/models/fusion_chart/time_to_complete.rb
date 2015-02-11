################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class FusionChart

   def time_to_complete(filters, requests_from_data)
    @filters = filters || {}
    data = []
    @applications = application_in_report
    @columns_to_select = "requests.started_at, requests.completed_at"

    all_req_ids = requests_from_data.select("requests.id")
    requests = refectored_requests(all_req_ids, "complete","app_id")
      
    @applications.each do |app|
      reqs = requests[app.id] || []
      reqs.uniq!
      completion_duration = reqs.blank? ? [0] : cal_completion_time(reqs)
      
      s = completion_duration.size

      if s >= 5
       completion_duration = completion_duration          
      elsif (s == 3 || s == 4)
       completion_duration = completion_duration * 2
      elsif s == 2 
       completion_duration = completion_duration * 3
      elsif s == 1
       completion_duration = completion_duration * 5
      elsif s == 0
       completion_duration = [0] * 5
      end
      
      completion_duration.flatten!
      data << { :app_name => app.name,
                :completion_time => completion_duration,
                :request_url => "j-displayRequests([#{request_ids(reqs)}])",
                :request_ids => reqs.map(&:id).to_json
              }
    end 

    data = data.sort_by {|hsh| hsh[:completion_time].flatten.compact}.reverse
  end

  def cal_completion_time(requests)
     time_count = [] 
      requests.each do |request|
        time_count << request.completion_time_in_minutes
      end
      time_count.flatten
  end

 def request_ids(requests)
    (requests || []).map(&:id).join(',') 
  end
    
  def application_in_report
    if filters[:app_id].present?
      App.id_equals(filters[:app_id])
    else
      User.current_user.accessible_apps
    end  
  end
  
end

