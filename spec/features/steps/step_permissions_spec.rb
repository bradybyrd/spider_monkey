require 'spec_helper'

feature 'Step permissions', js: true, custom_roles: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given!(:team) { create(:team, groups: user.groups) }
  given!(:restricted_environment) { create(:environment) }
  given!(:environment_with_access) { create(:environment) }
  given!(:restricted_role) { create(:role) }
  given!(:package) { create(:package) }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }
  given(:restricted_role_permissions) { TestPermissionGranter.new(restricted_role.permissions) }

  given(:basic_permissions) do
    [
      'Requests', 'View Requests list', 'Inspect Request',
      'Create Requests', 'Modify Requests Details', 'Inspect Steps',
      'Add New Step', 'Edit Steps', 'View created Requests list'
    ]
  end

  given(:managing_permissions) do
    [
      'Select Component', 'Edit Step Component Versions', 'Select Package',
      'Select Instance'
    ]
  end

  background do
    permissions << basic_permissions << managing_permissions
    restricted_role_permissions << basic_permissions
    user.groups.first.roles << restricted_role
    app = create(:app, environments: [restricted_environment, environment_with_access], components: [create(:component)])
    user.apps << app
    create(:application_package, app: app, package: package)
    app.application_components.last.installed_components.create(application_environment_id: app.application_environments.last.id)
    app.application_components.last.installed_components.create(application_environment_id: app.application_environments.first.id)
    AssignedEnvironment.create!(environment_id: restricted_environment.id, assigned_app_id: user.assigned_apps.first.id, role: user.roles.first)
    AssignedEnvironment.create!(environment_id: environment_with_access.id, assigned_app_id: user.assigned_apps.first.id, role: user.roles.first)
    create(:team_group_app_env_role, team_group: team.team_groups.first, application_environment: app.application_environments.first, role: restricted_role)
    create(:development_team, team: team, app: app)
    sign_in user
  end

  describe 'per application environment' do
    context 'w/o packaging and component permissions' do
      scenario 'user cannot select packages, components and acccess content tab' do
        request = create(:request, apps: [user.apps.first], environment: restricted_environment)
        visit edit_request_path(request)

        click_link I18n.t('step.buttons.new')
        wait_for_ajax

        within '.step_form' do
          expect(all('#step_related_object_type option[disabled]').count).to eq 3
          expect(find('#step_component_id')).to be_disabled

          within '#step_form_tabs' do
            expect(page).not_to have_link 'Content'
          end
        end
      end
    end

    context 'with packaging and component permissions' do
      scenario 'user can select packages, components and acccess content tab' do
        pending("randomly failing in spec")
        request = create(:request, apps: [user.apps.first], environment: environment_with_access)
        request.plan_it!
        visit edit_request_path(request)

        click_link I18n.t('step.buttons.new')
        wait_for_ajax

        within '.step_form' do
          expect(all('#step_related_object_type option[disabled]').count).to eq 0

          select(request.available_components.first.name, from: 'step_component_id')

          expect(find('#step_version')).not_to be_disabled
          expect(find('#step_own_version')).not_to be_disabled

          select('Package', from: 'step_related_object_type')
          select(package.name, from: 'step_package_id')

          within '#step_form_tabs' do
            expect(page).to have_link 'Content'
          end
        end
      end
    end

    context 'with component permissions, w/o versioning and packages' do
      scenario 'user can select components only' do
        pending("randomly failing in spec")
        restricted_role_permissions << 'Select Component'
        request = create(:request, apps: [user.apps.first], environment: restricted_environment)
        request.plan_it!
        visit edit_request_path(request)

        click_link I18n.t('step.buttons.new')
        wait_for_ajax

        within '.step_form' do
          expect(find(:select, 'step_related_object_type').find(:option, 'Package')).to be_disabled

          select(request.available_components.first.name, from: 'step_component_id')
          expect(find('#step_version')).to be_disabled
          expect(find('#step_own_version')).to be_disabled
        end
      end
    end

    context 'with package permissions, w/o instance and components' do
      scenario 'user can select packages only and see content tab' do
        pending("randomly failing in spec")
        restricted_role_permissions << 'Select Package'
        request = create(:request, apps: [user.apps.first], environment: restricted_environment)
        visit edit_request_path(request)

        click_link I18n.t('step.buttons.new')
        wait_for_ajax

        within '.step_form' do
          expect(find(:select, 'step_related_object_type').find(:option, 'Component')).to be_disabled

          select('Package', from: 'step_related_object_type')
          select(package.name, from: 'step_package_id')

          expect(find('#package_instance_id')).to be_disabled
          within '#step_form_tabs' do
            expect(page).to have_link 'Content'
          end
        end
      end
    end

  end
end
