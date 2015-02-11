################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class HudsonScriptsController < ApplicationController
  
  include ControllerSharedScript

  before_filter :find_integration, :only => [:find_jobs, :build_job_parameters]

  def find_script_template
    script = script_type(params[:id]) 
    render :text => script.content
  end
  
  def find_jobs
    jobs = HudsonScript.get_hudson_jobs(@integration)
    job_options = jobs.collect{|j| "<option value='#{j}'>#{j}</option>"}
    render :text => "<option value=''>Select</option>" + job_options.join
  end
  
  def build_job_parameters
    if (params[:script_id] && !params[:script_id].blank?)
      script = script_type(params[:script_id])
    end
    new_content = HudsonScript.hudson_parameters_to_arguments(params[:job], @integration, script.nil? ? "" : script.content)
    render :text => new_content
  end
  
  private 
  
    def find_integration
      @integration = ProjectServer.find(params[:id])
    end
    
    def hudson?
      true
    end
    
    def bladelogic?
      false
    end

    def capistrano?
      false
    end
    
    def script_type(script_id)
      @script = Script.find(script_id)
    end
  
   def use_template
     'hudson'
   end
end
