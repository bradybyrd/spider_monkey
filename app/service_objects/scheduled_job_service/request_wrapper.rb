################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module ScheduledJobService
  class RequestWrapper

    REQUEST_JOB_NAME = 'RunRequestJob'

    def initialize(resource)
      @resource = resource
    end

    def get_class
      REQUEST_JOB_NAME
    end

    def get_at_time
      @resource.scheduled_at.to_time
    end

    def get_description
      "This is auto-start job for Request ##{@resource.number} '#{@resource.name}' at: #{@resource.scheduled_at}"
    end

  end
end