require 'spec_helper'

describe TeamGroupAppEnvRolesController do

  describe '#set' do
    let(:app)   { create :app }
    let(:env)   { create :environment, apps: [app] }
    let(:group) { create :group }
    let(:team)  { create :team, groups: [group] }
    let(:role)  { create :role }
    let(:team_group_id)               { TeamGroup.where(team_id: team.id, group_id: group.id).first.id }
    let(:application_environment_id)  { ApplicationEnvironment.where(app_id: app.id, environment_id: env.id).first.id }

    let(:params)                     { { team_group_app_env_role: {
      application_environment_id: application_environment_id,
      team_group_id:              team_group_id,
      role_id:                    role.id
    }} }

    it 'saves to the DB' do
      expect{post :set, params}.to change{TeamGroupAppEnvRole.count}.by(1)
    end

    it 'renders nothing' do
      post :set, params
      expect(response.body).to eq ' '
    end
  end

end
