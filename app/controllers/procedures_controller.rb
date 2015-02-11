################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class ProceduresController < ApplicationController
  include ArchivableController
  include ObjectStateController

  def new
    @procedure = Procedure.new
    authorize! :create, @procedure
    @apps = App.active.name_order
  end

  def load_tab_data
    if params[:step_id]
      @step = Step.find(params[:step_id])
    else
      @procedure ||= find_procedure
      @step = @procedure.steps.build(:owner => current_user)
    end
  end

  def index
    @per_page= params[:per_page] || 20
    @page = params[:page] || 1
    @procedures = Procedure.unarchived.visible_in_index.order(:name).paginate(page: @page, per_page: @per_page)
    @archived_procedures = Procedure.archived.order(:name).paginate(page: @page, per_page: @per_page)
  end

  def edit
    begin
      @procedure ||= find_procedure
      authorize! :edit, @procedure
      @apps = App.active.name_order
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Procedure you are trying to access either does not exist or has been deleted"
      request.xhr? ? ajax_redirect(root_path) : redirect_to(root_path) && return
    end
  end

  def create
    authorize! :create_procedure, Request.new
    if params[:procedure][:step_ids].present?
      step_ids = params[:procedure][:step_ids].first.split(",").map(&:to_i)
      steps = Step.find(step_ids)
      steps.sort!{ |a,b| a.position <=> b.position }
    else
      req = Request.find(params[:request_id])
      steps = req.steps_for_procedure_creation
      unless steps.blank?
        if req.request_template && req.request_template.warning_state?
          flash[:warning] = req.request_template.warning_state
        end
      end
    end
    @procedure = build_procedure
    authorize! :create, @procedure
    unless steps.blank?
      @procedure.add_steps(steps)
      if @procedure.save
         if @procedure.warning_state?
           flash[:warning] =  @procedure.warning_state
         end
        if flash[:warning].blank?
          flash[:success] = "Procedure created successfully."
        end
        ajax_redirect(edit_request_path(steps.first.request))
      else
        show_validation_errors(:procedure)
      end
    else
      flash[:error] = "At least one enabled (ON) step should exist in the request to create procedure"
      ajax_redirect edit_request_path(Request.find(params[:request_id]))
    end
  end

  def new_procedure_template
    @procedure = Procedure.new(params[:procedure])
    authorize! :create, @procedure
    @procedure.created_by = current_user.id if current_user

    @apps = App.active.name_order
      if @procedure.save
        redirect_to after_create_path(@procedure)
        flash[:success] = "Procedure created successfully."
      else
        render :action => "new"
      end
  end

  def update
    @procedure = find_procedure
    authorize! :edit, @procedure
    params[:procedure][:name] = params[:procedure][:name].strip unless params[:procedure][:name].nil?
    @original_title = @procedure.name
    if @procedure.update_attributes(params[:procedure])
      flash[:success] = "Procedure was updated successfully"
      redirect_to  procedures_path
    else
      #FIXME: This error is cached and shown once the user moves to next page.
      flash[:error] = "There was a problem updating the procedure"
      edit
      render :action => 'edit'
    end
  end

  def update_step_position
    @procedure = Procedure.find(params[:procedure_id])

    @step = @procedure.steps.find(params[:id])

    @step.update_attributes(params[:step])

    render :partial => 'procedures/step_for_reorder', :locals => { :procedure => @procedure, :step => @step }
  end

  def destroy
    @procedure = Procedure.find(params[:id])
    authorize! :delete, @procedure
    @procedure.destroy

    redirect_to procedures_path, notice: t('activerecord.notices.deleted', model: Procedure.model_name.human)
  end

  def show
    redirect_to edit_procedure_path(params[:id])
  end

  def reorder_steps
    @procedure = find_procedure
  end

  def add_to_request
    @request            = Request.find_by_number(params[:request_id])
    authorize! :add_procedure, @request
    @procedure          = find_procedure
    procedure           = @request.steps.build(params[:step])
    procedure_construct = ProcedureService::ProcedureConstruct.new(procedure)
    procedure_construct.add_to_request(@procedure.steps)
    if @procedure.warning_state?
          flash[:warning] = @procedure.warning_state
    end
    # Added in audit log for more user friendly description. Steps_audit_log in procedure is added from model audit log
    ActivityLog.log_event(@request, current_user, "Added new procedure: #{@procedure.name}")

    if params[:from_request]
      redirect_to edit_request_path(@request)
    else
      render :partial => 'steps/procedure_for_reorder', :locals => { :request => @request, :step => procedure }
    end
  end

  def get_procedure_step_section
    @step = Step.find(params[:id])
    @only_preview = params[:preview]
    render :partial => 'steps/procedure_step_section', :locals => {:step => @step, :unfolded => true, :invalid_component => nil}
  end

  private

  def find_procedure
    Procedure.find(params[:id])
  end

  def build_procedure
    additional_attributes = { app_ids: params[:app_ids], created_by: current_user.id }
    Procedure.new(params[:procedure].merge(additional_attributes))
  end

  def after_create_path(procedure)
    if can? :edit, procedure
      edit_procedure_path procedure
    else
      procedures_path
    end
  end
end
