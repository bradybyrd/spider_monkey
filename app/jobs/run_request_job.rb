################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

class RunRequestJob

  def initialize(options = {})
    @logger = TorqueBox::Logger.new('ScheduledJobs')
    @job_descriptor = JobDescriptor.new(options)
    @service_wrapper = ScheduledJobService::ServiceWrapper
  end

  def run
    scheduled_job = ScheduledJob.scheduled.find(@job_descriptor.scheduled_job_id)

    request = scheduled_job.resource
    @logger.info("### START RUN request with id: #{request.id} name: #{request.name}")

    scheduled_job.update_job_status(ScheduledJob::IN_PROGRESS, 'In progress...')
    request.update_attributes(auto_start: false)

    precheck(request)
    start(request, scheduled_job)

    @logger.info("### FINISH RUN request with id: #{request.id} name: #{request.name}")
    remove_job
  end

  def on_error(exception)
    # Optionally implement this method to interrogate any exceptions
    # raised inside the job's run method.
    scheduled_job = ScheduledJob.find(@job_descriptor.scheduled_job_id)

    request = scheduled_job.resource
    @logger.info("### START [ERROR] request with id: #{request.id} name#{request.name} Exception: #{exception}")
    msg = "Request failed to start: #{exception}"
    full_msg = msg + "\nStackTrace: #{exception.backtrace.join(' ')}"

    scheduled_job.update_job_status_and_note(ScheduledJob::FAILED, full_msg, msg)

    request.update_attributes(auto_start: false) if request.auto_start
    @logger.info("### FINISH [ERROR] request with id: #{request.id} name#{request.name}")
    remove_job
  end

  private

  def precheck(request)
    return if request.may_start?
    raise "Request can't be started (probably some restrictions or it already started manually)."
  end

  def start(request, scheduled_job)
    raise 'Failed to start due: ' + request.errors.messages.to_s unless request.start!

    scheduled_job.update_job_status_and_note(ScheduledJob::COMPLETED,
                                             'Request auto started')
  end

  def remove_job
    scheduled_job_id = @job_descriptor.scheduled_job_id
    job_name = @job_descriptor.job_name
    @logger.info("### START REMOVE_JOB scheduled_job with id: #{scheduled_job_id} => #{job_name}")
    @service_wrapper::remove(job_name)
    @logger.info("### FINISH REMOVE_JOB scheduled_job with id: #{scheduled_job_id} => #{job_name}")
  end

end
