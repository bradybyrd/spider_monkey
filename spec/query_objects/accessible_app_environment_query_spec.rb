require "spec_helper"
require 'accessible_app_environment_query'

describe AccessibleAppEnvironmentQuery, custom_roles: true do
  let!(:user) { create(:old_user, :not_admin_with_role_and_group) }
  let!(:environment) { create(:environment) }
  let!(:restricted_environment) { create(:environment) }
  let!(:app) { create(:app, environments: [environment, restricted_environment]) }
  let!(:team) { create(:team, groups: user.groups) }
  let!(:development_team) { create(:development_team, team: team, app: app) }
  let!(:restricted_role) { create(:role) }
  let(:restricted_app_environment) {
    app.application_environments.where(environment_id: restricted_environment.id).first
  }
  let!(:team_group_app_env_role) {
    create(:team_group_app_env_role, team_group: team.team_groups.first, application_environment: restricted_app_environment, role: restricted_role)
  }
  let(:app_environment_query) { AccessibleAppEnvironmentQuery.new(user, permission.action, permission.subject) }

  let(:permissions) { user.groups.first.roles.first.permissions }
  let!(:permission) { create(:permission, name: 'Permission1', action: :list, subject: 'Subject') }

  before do
    permissions << permission
    user.groups.first.roles << restricted_role
  end

  describe '#accessible_app_envs' do
    it 'returns accessible application_environments' do
      expected_app_envs = app.application_environments.where(environment_id: environment.id)
      app_environment_query.accessible_app_envs.should =~ expected_app_envs
    end
  end

  describe '#accessible_env_ids' do
    it 'returns accessible environment ids' do
      sql = app_environment_query.accessible_env_ids.to_sql
      ActiveRecord::Base.connection.select_values(sql).should =~ [environment.id]
    end
  end

  describe '#accessible_app_env_ids' do
    it 'returns accessible environment ids' do
      expected_app_env = {"app_id" => app.id, "environment_id" => environment.id}
      sql = app_environment_query.accessible_app_env_ids.to_sql
      ActiveRecord::Base.connection.select_all(sql).should =~ [expected_app_env]
    end
  end
end