################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class FusionChart

  NonFunctionalRequests = [
    { :color => '#76A9E1',
     :title => 'Complete'
    },
    { :color => '#DE4C20',
     :title => 'Cancelled'
    }
  ]

  def completed_report
    data = []
    @columns_to_select = "requests.aasm_state"
    completed_requests = requests
    @requests = nil
    @fetch_cancelled_requests = true
    cancelled_requests = requests
    apps.each do |app|
      completed_reqs = completed_requests[app.id] || []
      completed_reqs.uniq!
      cancelled_reqs = cancelled_requests[app.id] || []
      cancelled_reqs.uniq!
      reqs = completed_reqs + cancelled_reqs
      data << { :app => app.name,
                :app_id => app.id,
                :requests => [completed_reqs.size, cancelled_reqs.size],
                :request_ids => reqs.map(&:id).to_json,
                :total_requests => reqs.size
               }
    end
    data.sort_by { |app| app[:total_requests] }
  end

end
