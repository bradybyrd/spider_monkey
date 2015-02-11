################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ServersController < ApplicationController
  include ControllerSoftDelete
  include AlphabeticalPaginator
  include PropertyUpdater

  before_filter :collect_server_groups, only: [:new, :edit]
  before_filter :collect_environments, only: [:new, :edit]

  def index
    authorize! :view, :environment_tab
    @per_page = 30
    @keyword = params[:key]
    associations_to_include = [:server_groups, :installed_components, :environments, :application_environments]
    accessible_servers = current_user.accessible_servers.includes(associations_to_include)
    @active_servers = accessible_servers.active
    @inactive_servers = accessible_servers.inactive
    if @keyword.present?
      @active_servers = @active_servers.search_by_ci("servers.name", @keyword)
      @inactive_servers = @inactive_servers.search_by_ci("servers.name", @keyword)
    end
    @total_records = @active_servers.length
    if @active_servers.blank? and @inactive_servers.blank?
      flash.now[:error] ||= "No Servers Found."
    end
    @active_servers = alphabetical_paginator @per_page, @active_servers
    render partial: 'list', layout: false if request.xhr?
  end

  def new
    @server = Server.new
    authorize! :create, @server
  end

  def edit
    @server = find_server
    authorize! :edit, @server
  end

  def create
    @server = Server.new(params[:server])
    @server.check_permissions = true

    if @server.save
      flash[:notice] = 'Server was successfully created.'
      redirect_to servers_path(:page => params[:page], :key => params[:key])
    else
      collect_and_render "new"
    end
  end

  def update
    params[:server] = {:environment_ids=>Array.new , :server_group_ids=>Array.new} unless params.key? :server
    params[:server][:environment_ids]  = Array.new unless params[:server].key? :environment_ids
    params[:server][:server_group_ids] = Array.new unless params[:server].key? :server_group_ids
    @server = find_server
    if params["name_update"].nil?
      update_all
    else
      update_name
    end
  end

  def destroy
    @server = find_server
    authorize! :delete, @server
    if @server.destroyable? && @server.destroy
      flash[:success] = I18n.t('activerecord.notices.deleted', model: I18n.t('activerecord.models.server'))
    else
      flash[:error] = I18n.t('activerecord.notices.not_deleted', model: I18n.t('activerecord.models.server'))
    end
    redirect_to servers_path(:page => (params[:page] ? params[:page] : 0),:key => params[:key])
  end

  protected

    def find_server
      Server.find params[:id]
    end

    def collect_server_groups
      @server_groups = ServerGroup.active.all(:order => 'name')
    end

    def collect_environments
      @environments = Environment.active.order("LOWER(name) asc")
    end

  private

    def update_name
    @server.check_permissions = true
    if @server.update_attributes(name: params[:server][:name].strip)
        redirect_to edit_server_path(@server, :page => (params[:page] ? params[:page] : 0),:key => params[:key])
      else
        collect_and_render "edit"
      end
    end

    def update_all
      @server.check_permissions = true
      begin
        if @server.update_attributes(params[:server])
          flash[:notice] = 'Server was successfully updated.'
          redirect_to servers_path(:page => params[:page], :key => params[:key])
        else
          collect_and_render "edit"
        end
      rescue ActiveRecord::RecordInvalid
        collect_and_render "edit"
      end
    end

    def collect_and_render(action_name)
      collect_server_groups
      collect_environments
      render :action => action_name
    end
end
