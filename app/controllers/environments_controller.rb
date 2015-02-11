################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

class EnvironmentsController < ApplicationController
  include ControllerSoftDelete
  include AlphabeticalPaginator

  before_filter :collect_servers_and_server_groups, only: [:new, :edit, :update_server_selects]
  before_filter :set_environment_types, :set_environment_states, only: [:new, :create, :edit, :update]
  skip_before_filter :verify_authenticity_token, only: [:environments_of_app]

  def index
    authorize! :list, Environment.new

    @per_page = 30
    @keyword = params[:key]
    @active_environments = current_user.accessible_environments.includes(:apps)
    @inactive_environments = current_user.inactive_accessible_environments.includes(:apps)
    if @keyword.present?
      @active_environments = @active_environments.search_by_ci('name', @keyword)
      @inactive_environments = @inactive_environments.search_by_ci('name', @keyword)
    end
    @total_records = @active_environments.length
    if @active_environments.blank? and @inactive_environments.blank?
      flash.now[:error] = 'No Environment found'
    end
    @active_environments = alphabetical_paginator @per_page, @active_environments
    render partial: 'index', layout: false if request.xhr?
  end

  def new
    @environment = Environment.new
    authorize! :create, @environment
  end

  def edit
    begin
      @environment = find_environment
      authorize! :edit, @environment
    rescue ActiveRecord::RecordNotFound
     flash[:error] = I18n.t(:'activerecord.notices.not_found', model: I18n.t('activerecord.models.environment'))
      redirect_to :back
    end
  end

  def create
    @environment = Environment.new(params[:environment])
    authorize! :create, @environment

    @environment.server_ids = params[:environment][:server_ids] || []
    @environment.default_server_id = params[:default_server_id] || (params[:environment][:server_ids] || []).first

    if @environment.save
      flash[:notice] = I18n.t(:'activerecord.notices.created', model: I18n.t('activerecord.models.environment'))
      redirect_to environments_path(page: params[:page], key: params[:key])
    else
      render action: 'new'
    end
  end

  def update
    @environment = find_environment
    authorize! :edit, @environment

    @environment.server_ids = params[:environment][:server_ids] || []
    @environment.default_server_id = params[:default_server_id] || (params[:environment][:server_ids] || []).first
    @environment.server_group_ids = params[:server_group_ids] || []

    if @environment.update_attributes(params[:environment])
      flash[:notice] = I18n.t(:'activerecord.notices.updated', model: I18n.t(:'activerecord.models.environment'))
      redirect_to environments_path(page: params[:page], key: params[:key])
    else
      render action: 'edit'
    end
  end

  def destroy
    @environment = find_environment
    if @environment.destroyable? && @environment.destroy
      flash[:success] = I18n.t('activerecord.notices.deleted', model: I18n.t('activerecord.models.environment'))
    else
      flash[:error] = I18n.t('activerecord.notices.not_deleted', model: I18n.t('activerecord.models.environment'))
    end

    redirect_to environments_path(page: params[:page], key: params[:key])
  end

  def update_server_selects
    @selected_server_group_ids = params[:environment][:server_group_ids] || []
    @selected_server_group_ids.map! { |id| id.to_i }

    @selected_server_groups = ServerGroup.find(@selected_server_group_ids)
    @selected_default_server_group_id = params[:environment][:default_server_group_id].to_i

    @selected_server_ids = params[:environment][:server_ids] || []
    @selected_server_ids = @selected_server_ids.map { |id| id.to_i } + @selected_server_groups.map { |server_group| server_group.server_ids }
    @selected_server_ids.flatten!
    @selected_server_ids.uniq!

    @selected_servers = Server.find(@selected_server_ids)
    @selected_default_server_id = params[:default_server_id].to_i
  end

  def create_default
    Environment.create_default
    authorize! :create, @environment

    redirect_to environments_path
  end

  def environments_of_app
    @app = App.find(params[:app_id])
    @environments = current_user.accessible_visible_environments_of_app(@app)
  end

  def metadata
    authorize! :access, :metadata
  end

protected

  def find_environment
    Environment.find params[:id]
  end

  def set_environment_types
    @environment_types = EnvironmentType.unarchived.in_order
  end

  def set_environment_states
    @environment_states = Environment.status_filters_for_select
  end

  def collect_servers_and_server_groups
    @servers = Server.active.all
    @server_groups = ServerGroup.active.all(order: 'name')
  end
end

