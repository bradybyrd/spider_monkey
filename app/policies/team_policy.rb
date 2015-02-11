################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class TeamPolicy
  attr_reader :team

  def initialize(team)
    @team = team
  end

  def disabled?(obj)
    @team.inactive? || data_default?(obj)
  end

  def data_default?(obj)
    [@team, obj].all?(&:default?)
  end

  def app_disabled?(app)
    disabled?(app) || last_team_for_app?(app)
  end

  def group_disabled?(group)
    disabled?(group) || (last_group_for_any_app?(group) && on_this_team?(group))
  end

  private

  def last_team_for_app?(app)
    teams_on_app = app.teams
    teams_on_groups_on_app = app.groups.includes(:teams).map(&:teams).flatten
    teams_on_both = teams_on_app & teams_on_groups_on_app
    [teams_on_app, teams_on_groups_on_app, teams_on_both].any? do |teams|
      teams == [team]
    end
  end

  def last_group_for_any_app?(group)
    apps = team.apps.includes(:groups, :teams)
    apps.any? do |app|
      app.groups == [group]
    end
  end

  def on_this_team?(group)
    team.groups.include?(group)
  end
end
