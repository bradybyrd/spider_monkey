################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ServerAspectGroupsController < ApplicationController
  include AlphabeticalPaginator

  def index
    authorize! :list, ServerAspectGroup.new
    @keyword = params[:key]
    @per_page = 30
    @server_aspect_groups = current_user.accessible_server_aspect_groups
    @server_aspect_groups = @server_aspect_groups.search_by_ci("server_aspect_groups.name", @keyword)  if @keyword.present?
    @total_records = @server_aspect_groups.length
    if @server_aspect_groups.blank?
      flash.now[:error] = "No Server Level Groups found."
    end
    @server_aspect_groups = alphabetical_paginator @per_page, @server_aspect_groups
    if params[:render_no_rjs].present?
      render :partial => "index", :layout => false
    end
  end

  def new
    @server_aspect_group = ServerAspectGroup.new
    authorize! :create, @server_aspect_group
    render :template => 'server_aspect_groups/load_form' if request.xhr?
  end

  def create
    @server_aspect_group = ServerAspectGroup.new(params[:server_aspect_group])
    @server_aspect_group.check_permissions = true
    if @server_aspect_group.save
      render :save
    else
      render :load_form
    end
  end

  def edit
    @server_aspect_group = ServerAspectGroup.find params[:id]
    authorize! :edit, @server_aspect_group
    render :template => 'server_aspect_groups/load_form' if request.xhr?
  end

  def update
    @server_aspect_group = ServerAspectGroup.find params[:id]
    @server_aspect_group.check_permissions = true
    if @server_aspect_group.update_attributes(params[:server_aspect_group])
      render :save
    else
      render :load_form
    end
  end

  def server_aspect_options
    server_level = ServerLevel.find_by_id(params[:server_aspect_group][:server_level_id])
    render :text => options_from_model_association(server_level, :server_aspects, :text_method => :path_string)
  end
end

