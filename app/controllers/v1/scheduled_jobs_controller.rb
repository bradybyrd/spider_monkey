################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::ScheduledJobsController < V1::AbstractRestController

  def index
    @scheduled_jobs = ScheduledJob.by_date rescue nil
    respond_to do |format|
      unless @scheduled_jobs.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => scheduled_jobs_presenter }
        format.json { render :json => scheduled_jobs_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  def show
    @scheduled_job = ScheduledJob.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @scheduled_job.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => scheduled_job_presenter }
        format.json { render :json => scheduled_job_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # special case of a model that can only be created through programmatic automation
  def create
    respond_to do |format|
      format.xml  { head :method_not_allowed }
      format.json  { head :method_not_allowed }
    end
  end

  # special case of a model that can only be created through programmatic automation
  def update
    respond_to do |format|
      format.xml  { head :method_not_allowed }
      format.json  { head :method_not_allowed }
    end
  end

  # special case of a model that can only be created through programmatic automation
  def destroy
    respond_to do |format|
      format.xml  { head :method_not_allowed }
      format.json  { head :method_not_allowed }
    end
  end

  private

  # helper for loading the scheduled_jobs presenter
  def scheduled_jobs_presenter
    @scheduled_jobs_presenter ||= V1::ScheduledJobsPresenter.new(@scheduled_jobs, @template)
  end

  # helper for loading the scheduled_job present
  def scheduled_job_presenter
    @scheduled_job_presenter ||= V1::ScheduledJobPresenter.new(@scheduled_job, @template)
  end
end
