################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module ScheduledJobsHelper

  def resource_name_with_link(scheduled_job)
    if scheduled_job.resource_type == 'Request'
      link_to(index_title(truncate(scheduled_job.resource.name, :length => 25).html_safe),
              request_path(scheduled_job.resource))
    elsif scheduled_job.resource_type == 'Run'
      scheduled_job.resource.name
    else
      'Unsupported'
    end
  end

end
