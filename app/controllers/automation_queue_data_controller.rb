################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AutomationQueueDataController < ApplicationController

  def index
  end

  def show
    @automation_queue_data = find_delay_job
  end

  def administration
    case params[:task]
      when 'clear_queue'
        authorize! :clear, AutomationQueueData.new
        AutomationQueueData.clear_queue!
      when 'restart'
        # TODO: remove this
      else
        "`task` not specified in params = #{params.inspect}"
    end
    redirect_to automation_monitor_path(:page => params[:page], :key => params[:key])
  end

protected

  def find_delay_job
    AutomationQueueData.find params[:id]
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "This job is completed and moved to job run log"
      redirect_to automation_monitor_path
  end

end

