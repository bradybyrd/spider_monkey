################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PhasesController < ApplicationController
  include ArchivableController

  def index
    authorize! :list, Phase.new
    @per_page= params[:per_page] || 20
    @page = params[:page] || 1
    @phases = Phase.unarchived.in_order.paginate(:page =>@page,:per_page => @per_page)
    @archived_phases = Phase.archived.in_order.paginate(:page =>@page,:per_page => @per_page)
  end

  def show
    begin
      @phase = Phase.find params[:id]
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Phase not found."
      @error_found = true
    end
    if @error_found
      redirect_to(phases_path)
    else
      render :action => :edit
    end
  end

  def new
    @phase = Phase.new
    authorize! :create, @phase
  end

  def edit
    begin
      @phase = find_phase
      authorize! :edit, @phase
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Phase you are trying to access either does not exist or has been deleted"
      redirect_to(phases_path) && return
    end
  end

  def create
    @phase = Phase.new(params[:phase])
    authorize! :create, @phase
    @phase.set_runtime_phases params[:runtime_phases]

    if @phase.save
      flash[:notice] = 'Phase was successfully created.'
      redirect_to phases_path
    else
      render :action => "new"
    end
  end

  def update
    @phase = find_phase
    authorize! :edit, @phase
    @phase.set_runtime_phases params[:runtime_phases]

    if @phase.update_attributes(params[:phase])
      flash[:notice] = 'Phase was successfully updated.'
      redirect_to phases_path
    else
      render :action => "edit"
    end
  end


  def destroy
    @phase = find_phase
    authorize! :delete, @phase
    @phase.destroy

    redirect_to phases_path
  end

  def destroy_runtime_phase
    @phase = find_phase
    runtime_phase = @phase.runtime_phases.find(params[:runtime_phase_id])
    render :json => runtime_phase.destroy
  end

  def reorder
    if params[:row_type] ==  "runtime_phase"
      runtime_phase =find_runtime_phase
      runtime_phase.update_attributes(params[:runtime_phase])
      render :partial => 'phases/runtime', :locals => { :runtime_phase => runtime_phase }
    else
      phase = find_phase
      phase.update_attributes(params[:phase])
      render :partial => 'phases/phase', :locals => { :phase => phase,:archived => false }
    end
  end

  protected
    def find_phase
      begin
        Phase.find params[:id]
      rescue ActiveRecord::RecordNotFound
        flash[:error] = "Phase not found."
        redirect_to :back
      end
    end

    def find_runtime_phase
      RuntimePhase.find params[:id]
    end

end
