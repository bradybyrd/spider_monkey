require "spec_helper"
require 'accessible_app_query'

describe AccessibleAppQuery, custom_roles: true do
  # users
  let!(:user) { create(:old_user) }
  let!(:other_user) { create(:old_user) }
  #permissions
  let!(:permission_for_check) { create(:permission, name: 'Permission for check', action: :check, subject: 'Subject for check') }
  let!(:permission_not_for_check) { create(:permission, name: 'Permission not for check', action: :not_check, subject: 'Subject not for check') }
  # roles
  let!(:role_with_permission){create(:role, name: 'Role with Permission to check', permissions: [permission_for_check])}
  let!(:role_without_permission){create(:role, name: 'Role without Permission to check', permissions: [permission_not_for_check])}
  #groups
  let!(:group_with_permission) do
    group = create(:group, name: 'Group with Permission to check', roles: [role_with_permission])
    user.groups << group
    group
  end
  let!(:group_without_permission) do
    group = create(:group, name: 'Group without Permission to check', roles: [role_without_permission])
    user.groups << group
    group
  end
  let!(:not_user_group) do
    group = create(:group, name: 'Group for other User', roles: [role_without_permission])
    other_user.groups << group
    group
  end
  # apps
  let!(:user_app_for_team_with_permission) { create(:app, name: 'App for team with permissions') }
  let!(:user_app_for_team_without_permission) { create(:app, name: 'App for team without permissions') }
  let!(:not_user_app) { create(:app, name: "Not user app") }
  # teams
  let!(:user_team_with_permission) do
    create(:team_with_apps_and_groups,
      name: 'User Team with Permission to check',
      apps: [user_app_for_team_with_permission],
      groups: [group_with_permission])
  end
  let!(:user_team_without_permission) do
    create(:team_with_apps_and_groups,
      name: 'User Team without Permission to check',
      apps: [user_app_for_team_without_permission],
      groups: [group_without_permission])
  end
  let!(:not_user_team) do
    create(:team_with_apps_and_groups,
      name: 'Not User Team',
      apps: [not_user_app],
      groups: [not_user_group])
  end

  let!(:app_query) { AccessibleAppQuery.new(user, permission_for_check.action, permission_for_check.subject) }

  describe '#app_by_team_role_scope' do
    it 'returns apps connected with teams' do
      result = app_query.app_by_team_role_scope.all

      result.should include(not_user_app)
      result.should include(user_app_for_team_with_permission)
      result.should include(user_app_for_team_without_permission)
    end
  end

  describe '#accessible_apps_with_user' do
    it 'returns apps connected with teams for particular user' do
      result = app_query.accessible_apps_with_user.all

      result.should_not include(not_user_app)
      result.should include(user_app_for_team_with_permission)
      result.should include(user_app_for_team_without_permission)
    end
  end

  describe '#accessible_apps' do
    it 'returns apps connected with teams for particular user and permission' do
      result = app_query.accessible_apps.all

      result.should_not include(not_user_app)
      result.should_not include(user_app_for_team_without_permission)
      result.should include(user_app_for_team_with_permission)
    end
  end
end