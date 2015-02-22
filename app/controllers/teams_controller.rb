################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class TeamsController < ApplicationController
  include ControllerSoftDelete
  include AlphabeticalPaginator

  before_filter :find_team, only: [:edit, :update, :destroy, :app_user_list,
     :add_apps, :remove_apps, :remove_groups, :add_groups]
  before_filter :collect_uniq_user_ids, only: [:create, :update]
  before_filter :check_default_app, only: [:update]
  before_filter :check_default_group, only: [:update]

  def index
    @per_page = 30
    @keyword = params[:key]
    teams = Team.search(@keyword)
    @active_teams = teams.active
    @inactive_teams = teams.inactive
    @total_records = @active_teams.length
    if @active_teams.blank? && @inactive_teams.blank?
      flash[:error] = 'No Team found.'
    end
    @active_teams = alphabetical_paginator @per_page, @active_teams
    render :partial => 'index', :layout => false if request.xhr?
  end

  def new
    @team = Team.new
    authorize! :create, @team
    @apps = App.active.all(:order => 'name')
    @groups = paginated_groups
  end

  def create
    @team = Team.new(params[:team])
    authorize! :create, @team
    @team.user_id = current_user.id # user who creates team
    team_saved = @team.manage_apps_and_users(:add, params[:team]) do |team|
      team.save
    end
    render_or_redirect?(team_saved)
  end

  def edit
    authorize! :edit, @team
    @apps = App.active.all(:order => 'name')
    @groups = paginated_groups
  end

  # GET
  def team_groups
    @team = params[:id].present? ? Team.find(params[:id]) : Team.new(params[:team])
    @groups = paginated_groups

    respond_to do |format|
      format.js { render 'update_user_list' }
    end
  end

  def update
    render_or_redirect?(@team.update_attributes(name: params[:team][:name]))
  end

  def destroy
    if @team.destroyable? && @team.destroy
      #PermissionMap.instance.bulk_clean(@team.users)
      flash[:success] = I18n.t('activerecord.notices.deleted', model: I18n.t('activerecord.models.team'))
    else
      flash[:error] = I18n.t('activerecord.notices.not_deleted', model: I18n.t('activerecord.models.team'))
    end
    ajax_redirect(teams_path)
  end

  def deactivate
    @team = find_team
    authorize! :make_active_inactive, @team
    #PermissionMap.instance.bulk_clean(@team.users)

    flash[:error] = t('team.deactivate_error') unless @team.deactivate!
    redirect_to teams_path(page: params[:page], key: params[:key])
  end

  def app_user_list
    @render_only_app_name = params[:render_only_app_name].present? && params[:render_only_app_name] == '1'

    # TODO: refactor
    if !@render_only_app_name
      @team                       = Team.includes(groups: :roles).find(params[:id])
      @app                        = App.includes(:environments).find(params[:app_id]) if params[:app_id].present?
      group_ids                   = @team.groups.map{|g| g.id}
      environment_ids             = @app.environments.map{|e| e.id}
      team_group                  = TeamGroup.where(group_id: group_ids, team_id: @team.id) #.group_by{|tg| tg.group_id}
      application_environment     = ApplicationEnvironment.where(app_id: @app.id, environment_id: environment_ids) #.group_by{|ae| ae.environment_id}
      selected_per_app_env_roles  = TeamGroupAppEnvRole.where(team_group_id: team_group.map(&:id),
                                                              application_environment_id: application_environment.map(&:id))
      @data                       = {team_group: team_group,
                                     application_environment: application_environment,
                                     selected_per_app_env_roles: selected_per_app_env_roles}
    else
      @app = App.find(params[:app_id]) if params[:app_id].present?
    end

    render :partial => 'teams/forms/user_role_list_by_app'
  end

  # POST/id
  def add_apps
    @team.manage_apps_and_users(:add, params) { |team, app_ids| team.app_ids += app_ids }
    #PermissionMap.instance.bulk_clean(@team.users)

    respond_to do |format|
      format.js { render partial: 'teams/forms/edit_applications' }
    end
  end

  # POST/id
  def remove_apps
    @team.manage_apps_and_users(:remove, params) { |team, app_ids| team.app_ids -= app_ids }
    #PermissionMap.instance.bulk_clean(@team.users)

    respond_to do |format|
      format.js { render partial: 'teams/forms/edit_applications' }
    end
  end

  # POST/id
  def add_groups
    @team.manage_apps_and_users(:add, params) { |team| team.group_ids += Array(params[:group_ids]).map(&:to_i) }
    @groups = paginated_groups
    #PermissionMap.instance.bulk_clean(@team.users)

    respond_to do |format|
      format.js { render partial: 'teams/forms/edit_groups' }
    end
  end

  # POST/id
  def remove_groups
    @team.manage_apps_and_users(:remove, params) { |team| team.group_ids -= Array(params[:group_ids]).map(&:to_i) }
    @groups = paginated_groups
    #PermissionMap.instance.bulk_clean(@team.users)

    respond_to do |format|
      format.js { render partial: 'teams/forms/edit_groups' }
    end
  end

  def get_user_list_of_groups
    if defined?(@fetch_users_data)
      @team_group = TeamGroup.where(team_id: params[:id]).all
      if @team_group.empty?
        user_selection = 'Users'
      else
        user_selection = 'Groups'
      end
    else
      user_selection = params[:selection_type]
    end

    find_team unless params[:id] == ''

    if user_selection == 'Groups'
      group_ids = defined?(@fetch_users_data) ? @team.group_ids : params[:group_ids].split(',')
      @active_users = User.active.not_placeholder.by_last_name.of_groups(group_ids)
    elsif user_selection == 'Users'
      user_ids = defined?(@fetch_users_data) ? @team.user_ids : params[:user_ids].split(',')
      @active_users = User.active.not_placeholder.by_last_name.selected_users_ids(user_ids)
    end

    @active_users = alphabetical_paginator 5, @active_users if @active_users

    unless defined?(@fetch_users_data)
      respond_to do |format|
        format.js { render :template => 'teams/update_user_list', :handlers => [:erb], :content_type => 'application/javascript' }
      end
    end
  end

  protected

  def find_team
    @team = Team.includes(:groups).find(params[:id])
  end

  def selected_users(user_ids)
    @selected_users = User.find(user_ids)
  end

  def render_or_redirect?(success)
    if success
      # clear_assoc_objects
      ajax_redirect(edit_team_path(@team, :page => params[:page_no], :key => params[:key]))
    else
      show_validation_errors(:team)
    end
  end

  def clear_assoc_objects
    @team.clear_assoc_objects({:apps => params[:team][:app_ids],
                               :groups => params[:team][:groups_ids],
                               :users => params[:team][:user_ids]})
    @team.remove_apps_from_assigned_apps
    @team.remove_users_from_team
  end

  def merge_user_ids
    params[:team].merge!({:user_ids => params[:check_box_selection].split(',')})
  end

  def collect_uniq_user_ids
    params[:team][:user_ids] = params[:team][:user_ids].uniq unless params[:team][:user_ids].nil?
  end

  private

  def paginated_groups
    groups = Group.order('lower(groups.name)').active
    per_page = params[:per_page].present? ? params[:per_page] : AlphabeticalPaginator::DEFAULT_PER_PAGE
    alphabetical_paginator per_page, groups
  end

  def check_default_app
    params[:team][:app_ids] << default_app.id if @team.default? && !app_ids.include?(default_app.id)
  end

  def default_app
    @default_app ||= App.default_app.first
  end

  def app_ids
    @app_ids ||= (params[:team][:app_ids] ||= []).map(&:to_i)
  end

  def check_default_group
    params[:team][:group_ids] << default_group.id if @team.default? && !group_ids.include?(default_group.id)
  end

  def default_group
    @default_group ||= Group.default_group
  end

  def group_ids
    @group_ids ||= (params[:team][:group_ids] ||= []).map(&:to_i)
  end
end
