################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class IntegrationProjectsController < ApplicationController

  include ControllerSoftDelete

  before_filter :find_integration_project, :except => :get_releases

  def index
    authorize_integration_projects_list!
    @active_projects = paginate_records(@project_server.projects.active.name_order, params, 30)
    @inactive_projects = @project_server.projects.inactive.name_order
  end

  def new
    @integration_project = @project_server.projects.new
    authorize!(:create, @integration_project)
  end

  def create
    @integration_project = @project_server.projects.new(params[:integration_project])
    authorize!(:create, @integration_project)

    if @integration_project.save
      flash[:notice] = "#{@integration_project.name} is successfully added"
      redirect_to project_server_integration_projects_url(@project_server)
    else
      render :action => "new"
    end
  end

  def edit
    authorize!(:edit, @integration_project)
  end

  def update
    authorize!(:edit, @integration_project)
    if @integration_project.update_attributes(params[:integration_project])
      flash[:notice] = "#{@integration_project.name} is successfully updated"
      redirect_to project_server_integration_projects_url(@project_server)
    else
      render :action => "edit"
    end
  end

  def destroy
    authorize!(:edit, @integration_project)
    if @integration_project && @integration_project.destroy
      flash[:notice] = "Project #{@integration_project.name} is deleted successfully"
    end
    redirect_to project_server_integration_projects_url(@project_server)
  end

  def get_releases
    integration_project = IntegrationProject.find(params[:id])
    render :text => options_from_model_association(integration_project,
                                                  :releases,
                                                  {:selected => params[:selected],
                                                    :include_blank => true
                                                  })
  end

  def activate
    authorize!(:make_active_inactive, @integration_project)
    @integration_project.activate!
    redirect_to project_server_integration_projects_path(@integration_project.project_server)
  end

  def deactivate
    authorize!(:make_active_inactive, @integration_project)
    @integration_project.deactivate!
    redirect_to project_server_integration_projects_path(@integration_project.project_server)
  end

  private

  def find_integration_project
    @project_server = ProjectServer.find(params[:project_server_id])
    @integration_project = @project_server.projects.find(params[:id]) if params[:id].present?
  end

  def authorize_integration_projects_list!
    raise CanCan::AccessDenied if cannot?(:create, IntegrationProject.new) && cannot?(:edit, IntegrationProject.new) && cannot?(:make_active_inactive, IntegrationProject.new)
  end
end
