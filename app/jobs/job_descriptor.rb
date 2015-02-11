################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class JobDescriptor

  attr_accessor :scheduled_job_id, :job_name
  # @scheduled_job_id - id of record at ScheduledJobs table
  # @job_name id      - by pattern "resource_id#resource_type"

  SCHEDULED_JOB_ID = 'scheduled_job_id'
  JOB_NAME         = 'job_name'

  def initialize(hash = nil)
    unless hash.nil?
      @scheduled_job_id = hash[SCHEDULED_JOB_ID]
      @job_name = hash[JOB_NAME]
    end
  end

  def to_hash
    {SCHEDULED_JOB_ID => scheduled_job_id, JOB_NAME => job_name}
  end

end