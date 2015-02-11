################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

module ScheduledJobService
  class ReschedulerService

    def initialize(opts={})
      @logger = TorqueBox::Logger.new('ScheduledJobs')
      @logger.info('ReschedulerService: Init')
    end

    def start
      Thread.new { run }
    end

    def run
      @logger.info("ReschedulerService: Start [#{object_id}]")
      reschedule
      @logger.info("ReschedulerService: Finish [#{object_id}]")
    end

    private

    def reschedule
      @logger.info('Inside reschedule')

      ScheduledJob.scheduled.each do |job|
        reschedule_on_server_start(job)
      end
    end

    def reschedule_on_server_start(job)
      if job.planned_at.future?
        @logger.info("Job: #{job.job_name} --> reschedule")
        job.schedule
      else
        @logger.info("Job: #{job.job_name} --> skipped (past time)")
        job.update_job_status_and_note(
            ScheduledJob::CANCELED,
            'Request was not able to schedule - planned date/time is at the past (probably server was down).')
        job.resource.update_attributes(auto_start: false)
      end
    end

  end
end