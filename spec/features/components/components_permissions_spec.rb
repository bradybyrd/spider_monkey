require 'spec_helper'
require 'cancan/matchers'

feature 'User on components page', custom_roles: true, js: true do
  given!(:user)         { create(:user, :non_root, :with_role_and_group) }
  given!(:component)    { create(:component, name: 'Aldebaran') }
  given!(:app)          { create(:app, components: [component]) } # => user with assigned app can see the component
  given!(:team)         { create(:team) }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    permissions << 'Dashboard'
    assign_user_to_team(app, team, user.groups.first)
    sign_in user
  end

  context 'with permission' do
    scenario 'sees the list of the components' do
      expect(Component.accessible_components_to_user(user).uniq).to eq [component]
      permissions << 'View Components list'

      visit components_path

      expect(page).to have_css('div#components > table')
    end

    scenario 'creates a new component' do
      component_name  = 'what a wonderful component'
      permissions << 'View Components list' << 'Create Component'

      visit components_path

      click_on I18n.t(:'component.buttons.add_new')
      fill_in :component_name, with: component_name
      click_on I18n.t(:create)

      expect(page).to have_content component_created_message

      within('div#components > table') do
        expect(page).not_to have_content component_name # because it is not assigned to any app thus non root user cannot see it
      end
    end

    scenario 'edits the component' do
      new_component_name = 'Ferrari Factory'
      permissions << 'View Components list' << 'Edit Component'

      visit components_path

      click_link I18n.t(:edit)
      fill_in :component_name, with: new_component_name
      click_on I18n.t(:update)

      expect(page).to have_content component_updated_message

      within('div#components > table') do
        expect(page).to have_content new_component_name
      end
    end

    scenario 'sees not the make_inactive link because component is assigned to the app' do
      permissions << 'View Components list' << 'Make Inactive/Active Component'

      visit components_path

      expect(action_links).not_to have_link(I18n.t(:make_inactive))
    end

    scenario 'of non root sees not the delete link because component is assigned to the app' do
      inactive_component = create(:component, name: 'TRES4', active: false)
      app.components = [inactive_component]
      permissions << 'View Components list' << 'Delete Component'

      visit components_path

      expect(action_links).not_to have_link(I18n.t(:delete))
    end

    scenario 'of root clicks the delete link' do
      inactive_component = create(:component, name: 'TRES4', active: false)
      grant_group_root_permissions(user.groups[0])
      permissions << 'View Components list' << 'Delete Component'

      visit components_path

      click_on I18n.t(:delete)

      expect(page).not_to have_content(inactive_component.name)
    end

  end

  context 'without permission' do
    scenario 'cannot see the list of the components' do
      visit components_path

      expect(current_path).to eq root_path
    end

    scenario 'clicks at the create link' do
      permissions << 'View Components list'

      visit components_path

      expect(page).not_to have_link(I18n.t(:'component.buttons.add_new'))
    end

    scenario 'clicks at the edit link' do
      permissions << 'View Components list'

      visit components_path

      expect(action_links).not_to have_link(I18n.t(:edit))
    end

    scenario 'sees not the make_active_inactive link' do
      permissions << 'View Components list'

      visit components_path

      expect(action_links).not_to have_link(I18n.t(:make_inactive))
    end

    scenario 'clicks on a delete link' do
      inactive_component = create(:component, name: 'TRES4', active: false)
      app.components = [inactive_component]
      permissions << 'View Components list'

      visit components_path

      expect(action_links).not_to have_link(I18n.t(:delete))
    end
  end

  describe 'with global permissions' do
    given!(:global_role) { create(:role) }
    given!(:global_group) { create(:group, roles: [global_role]) }
    given(:global_permissions) { TestPermissionGranter.new(global_role.permissions) }

    background { global_group.resources << user }

    scenario 'can create component' do
      permissions << 'View Components list'
      global_permissions << 'Create Component'

      visit components_path

      expect(page).to have_link I18n.t(:'component.buttons.add_new')
    end

    scenario 'cannot edit component with application if there is no per application permission' do
      permissions << 'View Components list'
      global_permissions << 'Edit Component'

      visit components_path

      expect(action_links).not_to have_link I18n.t(:edit)
    end
  end

  describe 'permissions per application environments' do
    given!(:restricted_environment) { create(:environment) }
    given!(:restricted_role) { create(:role, permissions: []) }
    given(:restricted_app_environment) { app.application_environments.where(environment_id: restricted_environment.id).first }
    given(:app_component) { app.application_components.where(component_id: component.id).first }

    before do
      permissions << 'View Components list'
      user.groups.first.roles << restricted_role
      app.environments << restricted_environment
      create(:team_group_app_env_role, team_group: team.team_groups.first, application_environment: restricted_app_environment, role: restricted_role)
    end

    scenario "cannot edit component that is installed on restricted application's environment" do
      permissions << 'Edit Component'
      create(:installed_component, application_component: app_component, application_environment: restricted_app_environment)

      visit components_path

      expect(action_links).not_to have_link I18n.t(:edit)
    end

    scenario "can edit component if it is installed on both restricted and non restricted application's environments" do
      permissions << 'Edit Component'
      create_installed_components_on_restricted_and_non_restricted_environments

      visit components_path

      expect(action_links).to have_link I18n.t(:edit)
    end

    scenario 'environment restrictions for component installed on applications that are not assigned to user are ignored and application permissions are applied' do
      permissions << 'Edit Component'
      app_team_group = create_not_assigned_app_with_installed_component_on_restricted_environment_with_team_and_group

      visit components_path

      expect(action_links).to have_link I18n.t(:edit)

      # Now let's assign that app and its team with restricted permission configuration to user
      assign_user_to_team(*app_team_group)
      visit components_path

      expect(action_links).not_to have_link I18n.t(:edit)
    end
  end

  def grant_group_root_permissions(group)
    group.update_column(:root, true)
  end

  def component_created_message
    I18n.t(:'activerecord.notices.created', model: I18n.t(:'activerecord.models.component'))
  end

  def component_updated_message
    I18n.t(:'activerecord.notices.updated', model: I18n.t(:'activerecord.models.component'))
  end

  def action_links
    find('.action_links')
  end

  def create_installed_components_on_restricted_and_non_restricted_environments
    environment_with_access = create(:environment)
    app.environments << environment_with_access
    app_environment_with_access = app.application_environments.where(environment_id: environment_with_access.id).first
    create(:installed_component, application_component: app_component, application_environment: restricted_app_environment)
    create(:installed_component, application_component: app_component, application_environment: app_environment_with_access)
  end

  def create_not_assigned_app_with_installed_component_on_restricted_environment_with_team_and_group
    App.any_instance.stub(:give_access_to_creator)
    not_assigned_app_environment = create(:environment)
    not_assigned_app = create(:app, environments: [not_assigned_app_environment], components: [component])
    group_without_permissions = create(:group, roles: [restricted_role])
    not_assigned_team = create(:team_with_apps_and_groups_env_roles, apps: [not_assigned_app],
      groups_config: [{ group: group_without_permissions,
        app_env_roles: [{ app: not_assigned_app, env: not_assigned_app_environment,
          role: restricted_role, component: component
        }]
      }]
    )

    [not_assigned_app, not_assigned_team, group_without_permissions]
  end

  def assign_user_to_team(new_app, new_team, new_group)
    create(:development_team, app: new_app, team: new_team)
    create(:team_group, team: new_team, group: new_group)
    user.apps << new_app
  end
end
