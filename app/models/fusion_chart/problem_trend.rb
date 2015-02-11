################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class FusionChart

  def problem_trend_report(filters, requests_from_data)
    @do_not_filter_by_step = true
    @filters = filters || {}
    @join = "INNER JOIN steps ON steps.request_id = requests.id"
    problem_trend_report_by_intervals(requests_from_data)
  end

  def problem_trend_report_by_intervals(requests_from_data)
    start_date = @filters[:beginning_of_calendar].present? ? @filters[:beginning_of_calendar] : DateTime.now-150 
    end_date = @filters[:end_of_calendar].present? ? @filters[:end_of_calendar] : DateTime.now   
    intervals = @filters[:precision] == "week" ? date_range_by_week(start_date, end_date) : date_range_by_month(start_date, end_date)
    all_req_ids = requests_from_data.select("requests.id")
    requests = refectored_requests(all_req_ids, ["problem", "hold", "cancelled"])

    if requests.present?
      group_by_problem_trend(intervals, requests)
    else
      []
    end
  end

  def group_by_problem_trend(intervals, requests)
    data = []
    problematic_requests = []
    group_by_array.each do |group_by|
      request_id = group_by.steps.where(:aasm_state => ['problem','blocked']).map(&:request_id).uniq
      request_count = []
      intervals.each do |date_hash|
        problematic_requests = if !request_id.empty?
          requests.get_all_problematic_request(request_id.flatten, date_hash)
          else
            []
          end
        request_id_array = problematic_requests.map(&:id).uniq.to_json
        problematic_requests_count = problematic_requests.map(&:id).uniq.count
        request_count << {"#{date_hash['start'].strftime('%d')} to #{date_hash['end'].strftime('%d-%B-%y')}" => problematic_requests_count, "request_link" => "j-displayRequests(#{request_id_array})"
          }
      end
      
      data << { "category" => group_by.name,
                "request_count" => request_count
              }
    end 
    data    
  end

  def group_by_array
    if @filters[:group_on] == 'work task'
      work_task_in_report
    elsif @filters[:group_on] == 'component'
      component_in_report
    elsif @filters[:group_on] == 'group'
      group_in_report
    else
      user_in_report
    end     
  end

  def date_range_by_month(start_date, end_date)
    date_array = []
    number_of_month = (end_date.year*12+end_date.month) - (start_date.year*12+start_date.month) + 1
    number_of_month.times do 
      date_array << {
          "start" => start_date.at_beginning_of_month,
          "end" => start_date.at_end_of_month
      }
      start_date = start_date.at_end_of_month+1
    end
    date_array
  end

  def date_range_by_week(start_date, end_date)
    date_array = []
    cw_day =  start_date.cwday
    start_date = start_date - cw_day 
    end_date = end_date + cw_day
    if (end_date.mjd - start_date.mjd)%7 == 0
      number_of_weeks = (end_date.mjd - start_date.mjd)/7
    else
      number_of_weeks = (end_date.mjd - start_date.mjd)/7 + 1
    end
    number_of_weeks.times do 
      date_array << {
        "start" => start_date,
        "end" => start_date + 6
      }
      start_date = start_date + 7
    end
    date_array
  end

  def work_task_in_report
    if @filters[:work_task_id].present?
      WorkTask.includes(:steps).where("steps.aasm_state" => ['problem','blocked']).find(filters[:work_task_id])
    else
      WorkTask.includes(:steps).where("steps.aasm_state" => ['problem','blocked']).all
    end  
  end 

  def component_in_report
    if @filters[:component_id].present?
      Component.includes(:steps).where("steps.aasm_state" => ['problem','blocked']).find(filters[:component_id])
    else
      Component.includes(:steps).where("steps.aasm_state" => ['problem','blocked']).all
    end
  end 

  def user_in_report
    if @filters[:owner_id].present?
      User.includes(:steps).where("steps.aasm_state" => ['problem','blocked'], "users.id" => filters[:owner_id])
    else
      User.includes(:steps).where("steps.aasm_state" => ['problem','blocked'])
    end
  end

  def group_in_report
    if @filters[:group_id].present?
      Group.includes(:steps).where("steps.aasm_state" => ['problem','blocked'], "groups.id" => filters[:group_id])
    else
      Group.includes(:steps).where("steps.aasm_state" => ['problem','blocked'])
    end
  end

end

