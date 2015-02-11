################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class EnvironmentTypesController < ApplicationController
  include ArchivableController

  def index
    authorize! :view, :environment_tab
    authorize! :list, EnvironmentType.new

    @per_page = params[:per_page] || 20
    @page = params[:page] || 1
    @environment_types = EnvironmentType.in_order.unarchived.paginate(page: @page, per_page: @per_page)
    @archived_environment_types = EnvironmentType.in_order.archived.paginate(page: @page, per_page: @per_page)
  end

  def new
    @environment_type = EnvironmentType.new
    authorize! :create, @environment_type
  end

  def edit
    begin
      @environment_type = find_environment_type
      authorize! :edit, @environment_type
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Environment type you are trying to access either does not exist or has been deleted"
      redirect_to(environment_types_path) && return
    end
  end

  def create
    @environment_type = EnvironmentType.new(params[:environment_type])
    authorize! :create, @environment_type

    if @environment_type.save
      flash[:notice] = 'Environment type was successfully created.'
      redirect_to environment_types_path
    else
      render :action => "new"
    end
  end

  def update
    @environment_type = find_environment_type
    authorize! :edit, @environment_type

    if @environment_type.update_attributes(params[:environment_type])
      flash[:notice] = 'Environment type was successfully updated.'
      redirect_to environment_types_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @environment_type = find_environment_type
    authorize! :delete, @environment_type
    @environment_type.destroy

    redirect_to environment_types_path, :notice => 'Environment type was successfully deleted.'
  end

  def reorder
    environment_type = find_environment_type
    authorize! :edit, environment_type
    environment_type.update_attributes(params[:environment_type])

    render :partial => 'environment_types/environment_type', :locals => { :environment_type => environment_type ,:archived => false}
  end

  protected

  def find_environment_type
    begin
      EnvironmentType.find params[:id]
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Environment type not found."
      redirect_to :back
    end
  end

end
