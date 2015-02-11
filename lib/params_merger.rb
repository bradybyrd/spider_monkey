################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ParamsMerger
  
  # This module contains methods that merge params to be used in methods used in general controllers and rest controller

  def request_params
    @request_params = ["app", "environment", "plan", "plan_stage", "request_template", "activity", "name"]
    #@request_params = ["app", "environment", "plan", "plan_stage", "request_template", "activity"]
  end
  
  def step_params
    @step_params = ["component"]
  end
  
  # This method can be used for 
  # RequestsController#create_request_from_template
  # RestController#create_request_from_template
  def merge_params_create_request_from_template
    params.merge!({:request => {}})
    request_params.each do |name|
      if name == "plan"
        #make special case plan_member_id find wi plan and plan_stage
      end
      
      # name has been added as a special parameter but cannot be objectified like the others
      unless name == "name"
        obj = name.classify.constantize.name_equals(params[name])
        params[:request].merge!({"#{name}_id" => obj[0].id}) unless obj.blank?
      else
        params[:request].merge!({:name => params[:name]}) unless params[:name].blank?
      end
    end
    if params[:request][:request_template_id].present?
      params[:request_template_id] = params[:request][:request_template_id]
      params[:include] = {"all"=>"1"}
      params[:request][:request_template_id] = nil
    end
    step_params.each do |name|
      obj = name.classify.constantize.name_equals(params[name])
      params.merge!({"#{name}_id" => obj[0].id}) unless obj.blank?
    end
  end
  
end
