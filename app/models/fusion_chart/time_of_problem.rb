################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class FusionChart

  def time_of_problem(filters, requests_from_data)
    @filters = filters
    @group_on = ( filters && filters["group_on"].present? ) ? find_group_param(filters)  : { :collection => (filters && filters.has_key?("owner_id") && filters["owner_id"].present? ? User.find(filters["owner_id"]).includes(:steps).where("steps.aasm_state" => ['problem', 'hold', 'block']) : User.active.includes(:steps).where("steps.aasm_state" => ['problem', 'hold', 'block'])), :group_by => "owner_id"}
    data = []
    @columns_to_select = "requests.aasm_state, steps.work_task_id, steps.component_id, steps.owner_id"
    @join = "INNER JOIN steps ON steps.request_id = requests.id"
    group_on = @group_on
    # requests_from_data = requests_from_data.where(:id => ActivityLog.select("request_id").where("activity like ':Step modification%'").
    #                                 where("activity like '%\"problem\"%'").uniq.map(&:request_id))  
    #requests = requests(requests_from_data, ["problem", "hold", "cancelled"], group_on[:group_by])
    all_req_ids = requests_from_data.select("requests.id")
    requests = refectored_requests(all_req_ids, ["problem", "hold", "cancelled"], group_on[:group_by])
    group_on[:collection].each do |obj|
      request_ids = []
      reqs = requests[obj.id] || []

      if filters && filters["group_on"] == "group"
        reqs = requests || []
      else
        reqs = requests[obj.id] || []
      end
      reqs.each do |req|
        #request_ids << req.id if obj.steps.where("steps.request_id = ?" => req.id, "steps.aasm_state" => ['problem', 'hold', 'block']).map(&:aasm_state).uniq.any?{|state| ['problem', 'hold', 'block'].include?(state)}
        request_ids << req.id if obj.steps.where("steps.request_id = ?" => req.id)
      end
      if request_ids.compact.blank?
       problem_duration = [0]
      else
#      request_ids.uniq!
#      reqs = Request.find(request_ids)
#      reqs.uniq!
#      problem_duration = reqs.blank? ? [0] : problem_time_by_status(reqs)
       reqs = Request.includes(:logs).find(request_ids)
       problem_duration =  problem_time_by_status(reqs)
      end
  
      s = problem_duration.size

      if s >= 5
       problem_duration = problem_duration          
      elsif (s == 3 || s == 4)
       problem_duration = problem_duration * 2
      elsif s == 2 
       problem_duration = problem_duration * 3
     elsif s == 1
       problem_duration = problem_duration * 5
      elsif s == 0
       problem_duration = [0] * 5
     end
      
      problem_duration.flatten!
      problem_requests = @problem_requests.present? ? @problem_requests.flatten : []
      data << { :obj_name => obj.name,
        :problem_time => problem_duration,
        :request_url => "j-displayRequests([#{request_ids(problem_requests)}])",
        :request_ids => problem_requests.map(&:id).to_json
      }
    end 
    data = data.sort_by {|hsh| hsh[:problem_time].flatten.compact}.reverse 
  end

  def request_ids(requests)
    (requests || []).map(&:id).join(',') 
  end

  def problem_time_by_status(requests)
    @problem_requests = []
    time_count = []
    requests.each do |request|
      # steps_time_in_hold
      # steps_time_in_blocked
      # steps_time_in_problem
      request_problem_duration = request.steps_time_in_problem + request.steps_time_in_hold + request.steps_time_in_blocked
      time_count << request_problem_duration / 60
      @problem_requests << request if request_problem_duration.to_f > 0.0
    end
    time_count.flatten
  end

  def find_group_param(filters)
    group_on = filters["group_on"]    
    case group_on
    when "work task"
      return {:collection => (filters.has_key?("work_task_id") && filters["work_task_id"].present? ? WorkTask.includes(:steps).where("steps.aasm_state" => ['problem', 'hold', 'block']).find(filters["work_task_id"]) : WorkTask.unarchived.includes(:steps).where("steps.aasm_state" => ['problem', 'hold', 'block']).all), :group_by => "work_task_id"}
    when "component"            
      return {:collection => (filters.has_key?("component_id") && filters["component_id"].present? ? Component.includes(:steps).where("steps.aasm_state" => ['problem', 'hold', 'block']).find(filters["component_id"]) : Component.active.includes(:steps).where("steps.aasm_state" => ['problem', 'hold', 'block']).all), :group_by => "component_id"}
    when "part of"      
      return {:collection => (filters.has_key?("owner_id") && filters["owner_id"].present? ? User.includes(:steps).where("steps.aasm_state" => ['problem', 'hold', 'block']).find(filters["owner_id"]) : User.active.includes(:steps).where("steps.aasm_state" => ['problem', 'hold', 'block'])), :group_by => "owner_id"}
    when "group"
      group_id = filters.has_key?("group_id") && filters["group_id"].present?
      return {:collection => (group_id ? Group.find(filters["group_id"], :include => :steps) : Group.active.all(:include => :steps)),:group_by =>""}
    end
  end

end

