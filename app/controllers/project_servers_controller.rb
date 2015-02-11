################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ProjectServersController < ApplicationController

  include AlphabeticalPaginator

  before_filter :find_project_server,
    :only => [
      :show, :edit, :update, :activate, :deactivate, :build_parameters
    ]

  # FIXME: In 3.2, this method is not found, gem or plugin suppressed?
  # resource_controller

  #show.wants.html { redirect_to project_servers_url }

  # stubbing out methods to avoid compiler errors
  def show
  end

  def edit
    authorize!(:edit, @project_server)
  end

  def destroy
    authorize!(:make_active_inactive, @project_server)
  end

  def new
    @project_server = ProjectServer.new
    authorize!(:create, @project_server)
  end

  def update
    authorize!(:edit, @project_server)
    if @project_server.update_attributes(params[:project_server])
      flash[:notice] = 'Project Server was successfully updated.'
      redirect_to project_servers_path
    else
      render :action => "edit"
    end
  end

  def create
    @project_server = ProjectServer.new(params[:project_server])
    authorize!(:create, @project_server)

    if @project_server.save
      flash[:notice] = 'Project Server was successfully created.'
      redirect_to project_servers_path
    else
      render :action => "new"
    end
  end

  def index
    authorize! :list, ProjectServer.new
    @per_page = 30
    @keyword = params[:key]
    @active_project_servers = ProjectServer.active
    @inactive_project_servers = ProjectServer.inactive
    if @keyword.present?
      @active_project_servers = @active_project_servers.search_by_ci("name", @keyword)
      @inactive_project_servers = @inactive_project_servers.search_by_ci("name", @keyword)
    end
    @total_records = @active_project_servers.count
    if @active_project_servers.blank? and @inactive_project_servers.blank?
      flash.now[:error] = "No Project Server Found"
    end
    @active_project_servers = alphabetical_paginator @per_page, @active_project_servers
    render :partial => "index", :layout => false if request.xhr?
  end

  def activate
    authorize!(:make_active_inactive, @project_server)
    @project_server.activate!
    redirect_to project_servers_url
  end

  def deactivate
    authorize!(:make_active_inactive, @project_server)
    @project_server.deactivate!
    redirect_to project_servers_url
  end

  def build_parameters
    original_data = params[:script_content]
    script_text = "\n# Integration server not found #"
    script_text = @project_server.add_update_integration_values(original_data, true) unless @project_server.nil?
    render :text => script_text, :layout => false
  end

  private

  def find_project_server
    @project_server = ProjectServer.find(params[:id])
  end

end
