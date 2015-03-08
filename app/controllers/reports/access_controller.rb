################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

class Reports::AccessController < ApplicationController
  def index
    authorize! :view, :access_reports
  end

  def roles_map
    authorize! :view, :roles_map_report

    @teams_for_select = Team.active
  end

  def roles_map_report
    authorize! :view, :roles_map_report

    respond_to do |format|
      format.html do
        render partial: 'reports/access/roles_map/roles_map_report',
               locals: { teams: selected_teams, groups: selected_groups, users: selected_users }
      end
      format.csv do
        csv_report = RolesMapCsv.new(selected_teams, selected_groups, selected_users)
        send_data csv_report.generate, type: 'text/csv', filename: 'roles_map.csv'
      end
    end
  end

  def groups_options_for_teams
    team_ids = params[:team_ids]
    if team_ids.blank?
      render nothing: true
    else
      groups = Group.active.of_teams(team_ids)
      render text: ApplicationController.helpers.options_from_collection_for_select(groups, :id, :name)
    end
  end

  def users_options_for_groups
    group_ids = params[:group_ids]
    if group_ids.blank?
      render nothing: true
    else
      users = User.select(['users.id', :first_name, :last_name]).active.of_groups(group_ids).order_by_name
      render text: ApplicationController.helpers.options_from_collection_for_select(users, :id, :name)
    end
  end

  private

  def selected_teams
    Team.where(id: (params[:team_ids] || [])).order('teams.name asc')
  end

  def selected_groups
    Group.where(id: (params[:group_ids] || [])).order('groups.name asc')
  end

  def selected_users
    User.where(id: (params[:user_ids] || [])).order_by_name
  end
end

