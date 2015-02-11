################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'


describe Team do
  describe '#filtered' do

    before(:all) do
      Team.delete_all
      @team1 = create_team(:active => true)
      @team2 = create_team(:active => false, :name => 'Smith')
      @team3 = create_team(:active => true, :name => 'John')
      @active = [@team1, @team3]
      @inactive = [@team2]
    end

    after(:all) do
      Team.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'John')
        result.should match_array([@team3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => 'Smith')
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:inactive => true, :name => 'Smith')
        result.should match_array([@team2])
      end
    end
  end

  describe "#role_environment_mappings=" do
    it "creates a new TeamGroupAppEnvRole if one does not exist" do
      team = create(:team)
      group = create(:group)
      application = create(:app)
      environment = create(:environment)
      role = create(:role)

      team.role_environment_mappings = [{
        "group_id" => group.id,
        "role_id" => role.id,
        "environment_id" => environment.id,
        "app_id" => application.id
      }]

      expected = team.team_group_app_env_roles(true).first
      expect(expected.team_group.team_id).to eq team.id
      expect(expected.team_group.group_id).to eq group.id
      expect(expected.application_environment.app_id).to eq application.id
      expect(expected.application_environment.environment_id).to eq environment.id
      expect(expected.role_id).to eq role.id
    end

    it "uses an existing TeamGroupAppEnvRole if one exists" do
      team = create(:team)
      group = create(:group)
      application = create(:app)
      environment = create(:environment)
      role = create(:role)
      team.role_environment_mappings = [{
        "group_id" => group.id,
        "role_id" => role.id,
        "environment_id" => environment.id,
        "app_id" => application.id
      }]
      original_team_group_app_env_role = team.team_group_app_env_roles(true).first
      new_role = create(:role)

      team.role_environment_mappings = [{
        "group_id" => group.id,
        "role_id" => new_role.id,
        "environment_id" => environment.id,
        "app_id" => application.id
      }]

      new_team_group_app_env_role = team.team_group_app_env_roles(true).first
      expect(new_team_group_app_env_role.id).
        to eq original_team_group_app_env_role.id
      expect(new_team_group_app_env_role.role).to eq new_role
    end

    it "removes existing TeamGroupAppEnvRoles if they aren't in the new list" do
      team = create(:team)
      group = create(:group)
      application = create(:app)
      environment = create(:environment)
      role = create(:role)
      team.role_environment_mappings = [{
        "group_id" => group.id,
        "role_id" => role.id,
        "environment_id" => environment.id,
        "app_id" => application.id
      }]
      original_team_group_app_env_role = team.team_group_app_env_roles(true).first
      new_role = create(:role)

      team.role_environment_mappings = []

      expect(team.team_group_app_env_roles(true)).to be_empty
    end
  end

  describe 'groups association' do
    it 'can be removed if app has more than 1 group through the teams' do
      app = build(:app)
      group = build(:group)
      another_group = build(:group)
      team = create(:team, groups: [group], apps: [app])
      create(:team, groups: [another_group], apps: [app])

      team.group_ids -= [group.id]

      expect(team.groups.size).to eq(0)
    end

    it 'cannot be removed if app has more 1 group through the teams' do
      app = build(:app)
      group = build(:group)
      team = create(:team, groups: [group], apps: [app])

      team.group_ids -= [group.id]

      expect(team.groups.size).to eq(1)
    end
  end

  describe 'apps association' do
    it 'can be removed if app has more than 1 group through the teams' do
      app = build(:app)
      group = build(:group)
      another_group = build(:group)
      team = create(:team, groups: [group], apps: [app])
      create(:team, groups: [another_group], apps: [app])

      team.app_ids -= [app.id]

      expect(team.apps.size).to eq(0)
    end

    it 'cannot be removed if that is the last app for the team' do
      app = build(:app)
      team = create(:team, apps: [app])

      team.app_ids -= [app.id]

      expect(team.apps.size).to eq(1)
    end

    it 'cannot be removed if app has more 1 group through the teams' do
      app = build(:app)
      group = build(:group)
      team = create(:team, groups: [group], apps: [app])

      team.app_ids -= [app.id]

      expect(team.apps.size).to eq(1)
    end
  end

  describe '#default' do
    it 'returns default team' do
      team = create(:default_team)
      expect(Team.default).to eq team
    end
  end

  describe '#add_group' do
    it 'does not add same group more than once' do
      team = create(:default_team)
      group = create(:group)

      team.add_group(group)
      team.add_group(group)

      expect(team.groups).to eq [group]
    end

    it "assigns group's users to the team's apps" do
      user = create(:user)
      app = create(:app)
      team = create(:default_team)
      team.apps = [app]
      group = create(:group)
      group.users = [user]

      team.add_group(group)

      expect(app.reload.users).to include user
    end
  end

  describe '#deactivate!' do
    it "updates assigned apps users" do
      team = create(:team)

      allow(team).to receive(:update_apps_users)
      team.deactivate!

      expect(team).to have_received(:update_apps_users)
    end
  end

  describe '#activate!' do
    it "updates assigned apps users" do
      team = create(:team)

      allow(team).to receive(:update_apps_users)
      team.activate!

      expect(team).to have_received(:update_apps_users)
    end
  end

  describe '#update_apps_users' do

    it "removes users from apps for inactive teams" do
      user = create(:user, :non_root)
      team = create(:team_with_apps_and_groups, groups: [])
      app = team.apps.first
      team.add_group(user.groups.first)

      expect(app.users).to include user

      team.update_attribute(:active, false)
      team.update_apps_users

      expect(app.reload.users).to_not include user
    end

    it "adds users to apps for active teams" do
      user = create(:user, :non_root)
      team = create(:team_with_apps_and_groups, groups: user.groups)
      app = team.apps.first

      expect(app.users).not_to include user
      team.update_apps_users
      expect(app.reload.users).to include user
    end
  end

  protected

  def create_team(options = nil)
    create(:team, options)
  end

end
