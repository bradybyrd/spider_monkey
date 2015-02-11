require "spec_helper"
require "permissions/permission_granters"

describe EnvironmentPermissionGranter, custom_roles: true do
  let(:permissions_list) { PermissionsList.new }
  let(:all_necessary_permissions) do
     [ create(:permission, permissions_list.permission('Create Deployment Windows Series')),
     create(:permission, permissions_list.permission('Edit Deployment Windows Series')) ]
  end
  let(:enabling_role) { create :role_with_permissions, name: 'Enabling role', permissions: all_necessary_permissions }
  let(:disabling_role) { create :role, name: 'Disabling role', permissions: [ create(:permission, action: :view, subject: :dashboard_tab) ] }
  let(:group) { create :group, roles: [enabling_role, disabling_role] }

   describe '#grant?'  do
    context 'user with one disabling create/edit deployment windows role and the other one enabling' do
      context 'with enabling environment' do
        it 'grants permissions for edit' do
          enabled_environment = create(:environment)
          user = create_user_with_environments(enabled: [enabled_environment], disabled: [])
          granter = EnvironmentPermissionGranter.new(user)
          deployment_window_series = build :deployment_window_series, environment_ids: [enabled_environment.id]

          result = granter.grant?(:edit, deployment_window_series)

          expect(result).to be_truthy
        end

        it 'grants permissions for create' do
          enabled_environment = create(:environment)
          user = create_user_with_environments(enabled: [enabled_environment], disabled: [])
          granter = EnvironmentPermissionGranter.new(user)
          deployment_window_series = build :deployment_window_series, environment_ids: [enabled_environment.id]

          result = granter.grant?(:create, deployment_window_series)

          expect(result).to be_truthy
        end
      end

      context 'with mutliple enabled environments in different orders' do
        it 'grants permissions for create' do
          enabled_environments = create_pair(:environment)
          user = create_user_with_environments(enabled: enabled_environments, disabled: [])
          granter = EnvironmentPermissionGranter.new(user)
          deployment_window_series = build :deployment_window_series, environment_ids: enabled_environments.map(&:id)

          result = granter.grant?(:create, deployment_window_series)

          expect(result).to be_truthy
        end
      end

      context 'with disabling environment' do
        it 'does not grant permissions for edit' do
          disabled_environment = create(:environment)
          user = create_user_with_environments(enabled: [], disabled: [disabled_environment])
          granter = EnvironmentPermissionGranter.new(user)
          deployment_window_series = build :deployment_window_series, environment_ids: [disabled_environment.id]

          result = granter.grant?(:edit, deployment_window_series)

          expect(result).to be_falsey
        end

        it 'does not grant permissions for create' do
          disabled_environment = create(:environment)
          user = create_user_with_environments(enabled: [], disabled: [disabled_environment])
          granter = EnvironmentPermissionGranter.new(user)
          deployment_window_series = build :deployment_window_series, environment_ids: [disabled_environment.id]

          result = granter.grant?(:create, deployment_window_series)

          expect(result).to be_falsey
        end
      end

      def create_user_with_environments(environments)
        application = create :app, environments: environments[:disabled] + environments[:enabled]
        enabled_app_env_roles = create_app_env_roles_for(application, environments[:enabled], enabling_role)
        disabled_app_env_roles = create_app_env_roles_for(application, environments[:disabled], disabling_role)
        create(:team_with_apps_and_groups_env_roles, apps: [application],
          groups_config: [{
            group: group,
            app_env_roles: (enabled_app_env_roles + disabled_app_env_roles)
          }]
        )
        create :user, :non_root, groups: [group]
      end

      def create_app_env_roles_for(application, environments, role)
        disabled_app_env_roles = environments.map do |environment|
          {
            app: application,
            env: environment,
            role: role
          }
        end
      end

    end
  end
end
