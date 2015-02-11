################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PlanStagesController < ApplicationController
  before_filter :find_plan_template

  before_filter :gather_selectbox_data, :only => [:edit, :create, :update, :new]

  def new
    @plan_stage = @plan_template.stages.build
    render :layout => false
  end

  def edit
    @plan_stage = find_plan_stage
    @request_templates = (@request_templates + @plan_stage.request_templates).uniq
    render layout: false
  end

  def create
    @plan_stage = @plan_template.stages.build(params[:plan_stage])
    if @plan_stage.save
      flash[:notice] = 'Plan stage was successfully created.'
      request.xhr? ? ajax_redirect(plan_template_path(@plan_template)) : redirect_to(plan_template_path(@plan_template))
    else
      request.xhr? ? show_validation_errors(:plan_stage, {:div => 'plan_stage_error_messages'}) : render(:action => "new")
    end
  end

  def update
    @plan_stage = find_plan_stage
     if !params[:plan_stage].key?(:request_template_ids)
      params[:plan_stage][:request_template_ids]=Array.new;
    end
    if @plan_stage.update_attributes(params[:plan_stage])
      flash[:notice] = 'Plan stage was successfully updated.'
      request.xhr? ? ajax_redirect(plan_template_path(@plan_template)) : redirect_to(plan_template_path(@plan_template))
    else
      request.xhr? ? show_validation_errors(:plan_stage, {:div => 'plan_stage_error_messages'}) : render(:action => "edit")
    end
  end

  def destroy
    @plan_stage = find_plan_stage
    @plan_stage.destroy
    redirect_to @plan_template
  end

  def reorder
    @plan_stage = find_plan_stage
    @plan_stage.update_attributes params[:plan_stage]
    render partial: 'plan_stages/plan_stage', locals: { plan_stage: @plan_stage, plan_template: @plan_template  }
  end

protected

  def find_plan_stage
    @plan_template.stages.find params[:id]
  end

  def find_plan_template
    @plan_template = PlanTemplate.find params[:plan_template_id]
    authorize! :edit, @plan_template
  end

  def gather_selectbox_data
    @request_templates = RequestTemplate.unarchived.templates_for(current_user,nil).visible('request_templates').name_order
    @environment_types = EnvironmentType.unarchived.in_order
  end
end
