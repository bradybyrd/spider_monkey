################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe TeamPolicy, custom_roles: true do
  let(:team) { create :default_team }
  let(:team_policy) { TeamPolicy.new team }
  let(:group) { create :group }
  let(:default_group) { create :default_group }
  let(:app) { create :app }
  let(:default_app) { create :default_app }

  context 'data_default' do
    it 'returns true when all object default' do
      expect(team_policy.data_default?(default_group)).to be_truthy
    end
    it 'returns false when at least one object is not default' do
      expect(team_policy.data_default?(group)).to be_falsey
    end
  end

  describe '#disabled?' do
    context 'team inactive' do
      before { team.update_attribute :active, false }

      it 'returns true' do
        expect(team_policy.disabled?(default_app)).to be_truthy
      end
    end

    context 'team active' do
      it 'returns true when all object default' do
        expect(team_policy.disabled?(default_app)).to be_truthy
      end

      it 'returns false when at least one object is not default' do
        expect(team_policy.disabled?(app)).to be_falsey
      end
    end
  end

  describe '#app_disabled?' do
    it 'returns true if 1 team connects app and group' do
      app = build(:app)
      group = build(:group)
      team = create(:team, name: 'Burn!', apps: [app], groups: [group])

      expect(TeamPolicy.new(team)).to be_app_disabled(app)
    end

    it 'returns false if 2 teams connect app and group' do
      app = build(:app)
      group = build(:group)
      teams = create_list(:team, 2, apps: [app], groups: [group])

      expect(TeamPolicy.new(teams[0])).not_to be_app_disabled(app)
    end

    it 'returns true if app belongs only to one team' do
      team = create(:team)
      app = build(:app, teams:[team])

      expect(TeamPolicy.new(team)).to be_app_disabled(app)
    end

    it 'returns true for the app that has a group in the only connecting team' do
      app = build(:app)
      team = create(:team, groups: [build(:group)], apps: [app])
      create(:team, apps: [app])

      expect(TeamPolicy.new(team)).to be_app_disabled(app)
    end

    context 'when app has a group through another team' do
      it 'returns false for the assigned app to the team' do
        app = build(:app)
        group = build(:group)
        create(:team, apps: [app], groups: [group])
        team = create(:team, apps: [app])

        expect(TeamPolicy.new(team)).not_to be_app_disabled(app)
      end

      it 'returns false for app which team has a group' do
        app = build(:app)
        group = build(:group)
        create(:team, apps: [app], groups: [group])
        team = create(:team, groups: [group])

        expect(TeamPolicy.new(team)).not_to be_app_disabled(app)
      end

      it 'returns false for the app that is assigned to the team' do
        app = build(:app)
        create(:team, groups: [build(:group)], apps: [app])
        team = create(:team, apps: [app])

        expect(TeamPolicy.new(team)).not_to be_app_disabled(app)
      end
    end
  end

  describe '#group_disabled?' do
    it 'returns true if app has 1 group through the team' do
      app = build(:app)
      group = build(:group)
      team = create(:team, name: 'Burn!', apps: [app], groups: [group])

      expect(TeamPolicy.new(team)).to be_group_disabled(group)
    end

    it 'returns true for the last group that is assigned to the app through the team regardless of another team with this group exists' do
      app = create(:app)
      group = create(:group)
      create(:team, groups: [group])
      team = create(:team, groups: [group], apps: [app])

      expect(TeamPolicy.new(team)).to be_group_disabled(group)
    end

    it 'returns true for the last group that is assigned to the app through the team regardless of another team with this app exists' do
      app = create(:app)
      group = create(:group)
      create(:team, apps: [app])
      team = create(:team, groups: [group], apps: [app])

      expect(TeamPolicy.new(team)).to be_group_disabled(group)
    end

    it 'returns false if group has not got app assigned through the team' do
      group = build(:group)
      team = create(:team, groups: [group])

      expect(TeamPolicy.new(team)).not_to be_group_disabled(group)
    end

    it 'returns false if there is another team that connects app with group' do
      app = build(:app)
      group = build(:group)
      create(:team, apps: [app], groups: [group])
      team = create(:team, apps: [app], groups: [group])

      expect(TeamPolicy.new(team)).not_to be_group_disabled(group)
    end

    context 'when group has an app through another team' do
      it 'returns false if current team has an app' do
        app = build(:app)
        group = build(:group)
        create(:team, apps: [app], groups: [group])
        team = create(:team, apps: [app])

        expect(TeamPolicy.new(team)).not_to be_group_disabled(group)
      end

      it 'returns false if group is assigned to the team' do
        app = build(:app)
        group = build(:group)
        create(:team, apps: [app], groups: [group])
        team = create(:team, groups: [group])

        expect(TeamPolicy.new(team)).not_to be_group_disabled(group)
      end
    end

  end
end
