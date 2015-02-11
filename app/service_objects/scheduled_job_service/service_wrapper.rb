################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

module ScheduledJobService
  class ServiceWrapper

    AT_JOB_CLASS_NAME = 'Java::OrgTorqueboxJobs::AtJob'

    class << self

      def list
        @jobs = TorqueBox::ScheduledJob.list.delete_if { |job| job.class.name != AT_JOB_CLASS_NAME }
      end

      def lookup(name)
        @job = TorqueBox::ScheduledJob.lookup(name)
      end

      def at(scheduled_job)
        resource = scheduled_job.resource

        wrapper = get_wrapper(resource)

        cfg = JobDescriptor.new
        cfg.scheduled_job_id = scheduled_job.id
        cfg.job_name = scheduled_job.job_name

        @result = TorqueBox::ScheduledJob.at(
          wrapper.get_class,
          at: wrapper.get_at_time,
          every: 600000,
          repeat: 1,
          name: scheduled_job.job_name,
          description: wrapper.get_description,
          config: cfg.to_hash)
      end

      def remove(name)
        if lookup(name).present?
          @result = TorqueBox::ScheduledJob.remove(name)
        end
      end

      def get_wrapper(resource)
        if resource.is_a? Request
          ScheduledJobService::RequestWrapper.new(resource)
        else
          raise 'Unsupported resource'
        end
      end

    end

  end
end