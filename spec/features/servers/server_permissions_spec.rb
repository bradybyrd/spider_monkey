require 'spec_helper'

feature 'Server page permissions', custom_roles: true, role_per_env: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given!(:team) { create(:team, groups: user.groups) }
  given!(:restricted_environment) { create(:environment) }
  given!(:environment_with_access) { create(:environment) }
  given!(:server_aspect) { create(:server_aspect) }
  given!(:server_aspect_group) { create(:server_aspect_group, server_aspects: [server_aspect]) }
  given!(:inactive_server) { create(:server, active: false) }
  given!(:app) { create(:app, environments: [restricted_environment, environment_with_access]) }

  given(:server) { server_aspect.server }

  given(:permissions) { user.groups.first.roles.first.permissions }

  given(:list_permission) { create(:permission, name: 'List', action: 'list', subject: 'Server') }

  given(:basic_permissions) do
    [
      create(:permission, name: 'Access Servers', action: 'view', subject: 'server_tabs'),
      create(:permission, name: 'Environment Tab', action: 'view', subject: 'environment_tab')
    ]
  end

  given(:managing_permissions) do
    [
      create(:permission, name: 'Create', action: 'create', subject: 'Server'),
      create(:permission, name: 'Edit', action: 'edit', subject: 'Server'),
      create(:permission, name: 'Delete', action: 'delete', subject: 'Server'),
      create(:permission, name: 'Active/Inactive', action: 'make_active_inactive', subject: 'Server')
    ]
  end

  background do
    create(:environment_server, server: server, environment: restricted_environment)
    create(:environment_server, server: inactive_server, environment: restricted_environment)
    user.apps << app
    create(:development_team, team: team, app: app)
    permissions << basic_permissions
    sign_in user
  end

  describe 'tabs' do
    context 'w/o list permission' do
      scenario 'tab not available' do
        visit servers_path

        within '.server_tabs' do
          expect(page).to have_no_link 'Servers'
        end
      end
    end

    context 'with list permission' do
      scenario 'tab available' do
        permissions << list_permission
        visit servers_path

        within '.server_tabs' do
          expect(page).to have_link 'Servers'
        end
      end
    end
  end

  describe 'list' do
    before do
      permissions << list_permission
    end

    context 'w/o managing permissions' do
      scenario 'can only see list' do
        visit servers_path

        within '.formatted_table.active' do
          expect(page).to have_no_link server.name
          expect(page).to have_content server.name
          expect(page).to have_no_link I18n.t(:make_inactive)
          expect(page).to have_no_link I18n.t(:edit)
        end

        within '.Right #sidebar' do
          expect(page).to have_no_link 'Create_server'
        end

        within '.formatted_table.inactive' do
          expect(page).to have_no_link I18n.t(:make_active)
          expect(page).to have_no_link I18n.t(:edit)
          expect(page).to have_no_link I18n.t(:delete)
        end
      end
    end

    context 'with managing permissions' do
      scenario 'can manage items' do
        Server.any_instance.stub(:destroyable?).and_return(true)
        permissions << managing_permissions
        visit servers_path

        within '.formatted_table.active' do
          expect(page).to have_link server.name
          expect(page).to have_link I18n.t(:make_inactive)
          expect(page).to have_link I18n.t(:edit)
        end

        within '.Right #sidebar' do
          expect(page).to have_link 'Create_server'
        end

        within '.formatted_table.inactive' do
          expect(page).to have_link I18n.t(:make_active)
          expect(page).to have_link I18n.t(:edit)
          expect(page).to have_link I18n.t(:delete)
        end
      end
    end
  end

  describe 'permissions by more restrictive role per environment' do
    let!(:restricted_role) { create(:role, permissions: [basic_permissions, list_permission].flatten) }

    before do
      Server.any_instance.stub(:destroyable?).and_return(true)
      permissions << [basic_permissions, list_permission, managing_permissions]
      user.groups.first.roles << restricted_role
      create(:team_group_app_env_role, team_group: team.team_groups.first, application_environment: app.application_environments.first, role: restricted_role)
    end

    scenario 'user can see page in read only mode' do
      visit servers_path

      within '.formatted_table.active' do
        expect(page).to have_no_link server.name
        expect(page).to have_content server.name
        expect(page).to have_no_link I18n.t(:make_inactive)
        expect(page).to have_no_link I18n.t(:edit)
      end

      within '.Right #sidebar' do
        expect(page).to have_link 'Create_server'
      end

      within '.formatted_table.inactive' do
        expect(page).to have_no_link I18n.t(:make_active)
        expect(page).to have_no_link I18n.t(:edit)
        expect(page).to have_no_link I18n.t(:delete)
      end
    end

    scenario 'validates creation of server for restricted per environment role and allows creation for non restricted', js: true do
      visit servers_path

      click_link 'Create_server'

      fill_in 'server_name', with: 'New Server'
      check restricted_environment.name
      click_button 'Create'

      within '#errorExplanation' do
        expect(page).to have_content I18n.t('permissions.action_not_permitted', action: 'create', subject: 'Server')
      end

      check environment_with_access.name
      click_button 'Create'

      within '#errorExplanation' do
        expect(page).to have_content I18n.t('permissions.action_not_permitted', action: 'create', subject: 'Server')
      end

      uncheck restricted_environment.name
      click_button 'Create'

      expect(page).to have_content 'Server was successfully created.'

      within '.formatted_table.active' do
        expect(page).to have_link 'New Server'
        expect(page).to have_link I18n.t(:make_inactive)
        expect(page).to have_link I18n.t(:edit)
      end

      click_link 'New Server'
      uncheck environment_with_access.name
      check restricted_environment.name
      click_button 'Update'

      within '#errorExplanation' do
        expect(page).to have_content I18n.t('permissions.action_not_permitted', action: 'edit', subject: 'Server')
      end

      uncheck restricted_environment.name
      check environment_with_access.name
      click_button 'Update'

      expect(page).to have_content 'Server was successfully updated.'

      within('.formatted_table.active') { click_link 'New Server' }
      check restricted_environment.name
      click_button 'Update'

      expect(page).to have_content 'Server was successfully updated.'
    end

    scenario 'user can create server with two (or more) environments he has access to' do
      another_environment_with_access = create(:environment)
      app.environments << another_environment_with_access
      visit servers_path

      click_link 'Create_server'

      fill_in 'server_name', with: 'New Server'
      check environment_with_access.name
      check another_environment_with_access.name
      click_button 'Create'

      expect(page).to have_content 'Server was successfully created.'
    end

    scenario 'user can create server for not assigned app environments and environments w/o apps' do
      App.any_instance.stub(:give_access_to_creator)

      environment_without_app = create(:environment)
      not_assigned_app_environment = create(:environment)
      create(:app, environments: [not_assigned_app_environment])
      visit servers_path

      click_link 'Create_server'

      fill_in 'server_name', with: 'New Server'
      check environment_without_app.name
      check not_assigned_app_environment.name
      click_button 'Create'

      expect(page).to have_content 'Server was successfully created.'
    end

    scenario 'user can create server if different apps have same environment and at least one environment has creation permission' do
      assigned_app = create(:app, environments: [restricted_environment])
      create(:development_team, team: team, app: assigned_app)
      visit servers_path

      click_link 'Create_server'

      fill_in 'server_name', with: 'New Server'
      check restricted_environment.name
      click_button 'Create'

      expect(page).to have_content 'Server was successfully created.'
    end
  end

  describe 'List by role per environment permissions' do
    given!(:restricted_role) { create(:role, permissions: basic_permissions) }

    before do
      permissions << [basic_permissions, list_permission]
      user.groups.first.roles << restricted_role
      restricted_app_environment = app.application_environments.where(environment_id: environment_with_access.id).first
      create(:team_group_app_env_role, team_group: team.team_groups.first, application_environment: restricted_app_environment, role: restricted_role)
    end

    scenario 'User can see servers that have list permission' do
      restricted_server = create(:server, environments: [environment_with_access])
      visit servers_path

      expect(page).to have_content server.name
      expect(page).to_not have_content restricted_server.name
    end

    scenario 'User cannot see servers of inactive team' do
      team.deactivate!
      visit servers_path

      expect(page).not_to have_content server.name
    end
  end
end
