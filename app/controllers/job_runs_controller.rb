################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class JobRunsController < ApplicationController
  include ControllerSearch
  
  def index
    @per_page = 50
    @keyword = params[:key]
    @job_runs = JobRun.completed_in_last("week")
    if @keyword.present?
      @job_runs = @job_runs.name_like(@keyword)
    end
    @total_records = @job_runs.length
    if @job_runs.blank?
      flash[:error] = "No Job Runs found."
    end
    @page = params[:page] || 1
    @job_runs =  paginate_records(@job_runs, params, @per_page) 
  end     
    
  def show
    @job_run = find_job_run
  end

  def destroy
    @job_run = find_job_run
    @job_run.destroy
    redirect_to automation_monitor_path(:page => params[:page], :key => params[:key])
  end
  
protected

  def find_job_run
    JobRun.find params[:id]
  end



end
