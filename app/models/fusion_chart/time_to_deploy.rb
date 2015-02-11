################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class FusionChart

  ColorCodesTitles = [
                       { :color => '#CCEF8E',
                         :title => 'Average of Actual Start to Complete (in minutes) for average # of requests'
                       },
                       { :color => '#82AEEB',
                         :title => 'Average of Actual Start to Complete (in minutes) for all requests'
                       }
                     ]


  def time_to_deploy
    data = []
    @columns_to_select = "requests.started_at, requests.completed_at"
    apps.each do |app|
      reqs = (requests[app.id] || []).sort_by(&:id)
      reqs.uniq!
      latest_reqs = if filters[:number_of_requests].present? && filters[:number_of_requests].to_i > 0
        reqs.last(filters[:number_of_requests].to_i)
      else
        reqs
      end
      total_time = reqs.map(&:completion_time_in_minutes).sum
      latest_requests_time = latest_reqs.map(&:completion_time_in_minutes).sum
      latest_requests_avg_time = latest_requests_time > 0 ? (latest_requests_time / latest_reqs.size).round : 0
      avg_time = total_time > 0 ? (total_time / reqs.size).round : 0
      data << { :app_id => app.id,
                :avg_time => avg_time,
                :info => [latest_requests_avg_time, avg_time],
                :app => app.name,
                :total_requests => reqs.size,
                :request_ids => reqs.map(&:id).to_json,
                :avg_requests => latest_reqs.size
              }
    end
    data.sort_by { |app| app[:avg_time] }
  end

end
