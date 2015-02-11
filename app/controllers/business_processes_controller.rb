################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class BusinessProcessesController < ApplicationController
  include ArchivableController

  def index
    authorize! :list, BusinessProcess.new
    @per_page = params[:per_page] || 20
    @page = params[:page] || 1
    @business_processes = BusinessProcess.unarchived.name_order.paginate(:page => @page, :per_page => @per_page)
    @archived_business_processes = BusinessProcess.archived.name_order.paginate(:page => @page, :per_page => @per_page)
  end

  def new
    @business_process = BusinessProcess.new
    authorize! :create, @business_process
  end

  def edit
    begin
      @business_process = find_process
      authorize! :edit, @business_process
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Business Process you are trying to access either does not exist or has been deleted"
      redirect_to(processes_path) && return
    end
  end

  def create
    @business_process = BusinessProcess.new(params[:business_process])
    authorize! :create, @business_process

    if @business_process.save
      flash[:notice] = 'BusinessProcess was successfully created.'
      redirect_to processes_path
    else
      render :action => "new"
    end
  end

  def update
    @business_process = find_process
    authorize! :edit, @business_process

    #
    # DEFECT: DE65293 - Metadata: JWO : Unselected Applications in a Process are shown again when the Process is updated.
    # Arvind: If none of the application is selected, it is not passed in params[:business_process].
    # Update does not make any change in :app_ids(which is in has_many relations). To fix this error
    # below, just passed empty array of app_ids parameter, which will give user error for BusinessProcess.validates_presence_of :app_ids
    #
    #
    if !params[:business_process].key?(:app_ids)
      params[:business_process][:app_ids]=Array.new;
    end

    begin
      @business_process.validate_updated_apps(params[:business_process][:app_ids])
    rescue ActiveRecord::Rollback
      flash[:error] = 'A request uses an app that you deselected as well as this business process.'
      @business_process = find_process
      return render :action => "edit"
    end

    if @business_process.update_attributes(params[:business_process])
      flash[:notice] = 'BusinessProcess was successfully updated.'
      redirect_to processes_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @business_process = find_process
    authorize! :delete, @business_process
    @business_process.destroy

    redirect_to(processes_path)
  end

  protected
    def find_process
      BusinessProcess.find params[:id]
    end

    alias find_business_process find_process

end
