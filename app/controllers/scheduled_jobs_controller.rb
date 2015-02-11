################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class ScheduledJobsController < ApplicationController

  # GET /scheduled_jobs
  def index
    @scheduled_jobs = ScheduledJob.accessible_to_user(current_user).by_date
    service_jobs = ScheduledJobService::ServiceWrapper.list

    @service_hash = {}
    service_jobs.each { |service| @service_hash[service.name] = service }

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /scheduled_jobs/1
  def show
    @scheduled_job = ScheduledJob.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

end
