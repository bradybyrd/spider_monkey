require 'spec_helper'

feature 'Integrations page permissions', custom_roles: true do
  given!(:user) { create(:old_user, :not_admin_with_role_and_group) }
  given!(:project_server) { create(:project_server, name: 'Server 42') }
  given!(:basic_permissions) { [
      create(:permission, name: 'View applications', action: :view, subject: :my_applications ),
      create(:permission, name: 'View dashboard tab', action: :view, subject: :dashboard_tab ),
      create(:permission, name: 'System tab view', action: :view, subject: :system_tab)
    ] }

  given(:permissions) { user.groups.first.roles.first.permissions }
  given(:permissions_list) { PermissionsList.new }

  given(:view_project_servers_permission) { create(:permission, name: 'View project servers list', action: :list, subject: 'ProjectServer') }
  given(:create_project_server_permission) { create(:permission, name: 'Create project server', action: :create, subject: 'ProjectServer') }
  given(:edit_project_server_permission) { create(:permission, name: 'Edit project server', action: :edit, subject: 'ProjectServer') }
  given(:make_inactive_project_server_permission) { create(:permission, name: 'Make active/inactive project server', action: :make_active_inactive, subject: 'ProjectServer') }
  given(:edit_integration_project_permission) { create(:permission, permissions_list.permission('Edit Integration Project')) }

  background do
    permissions << basic_permissions

    sign_in user
  end

  describe '"Integrations" tab' do
    scenario 'not available when user hasn"t "list project_servers" permission' do
      visit project_servers_path

      within '#primaryNav' do
        expect(page).to have_no_content 'Integrations'
      end
    end

    scenario 'available when user has "list project_servers" permission' do
      permissions << view_project_servers_permission
      visit project_servers_path

      within '#primaryNav' do
        expect(page).to have_link 'Integrations'
      end
    end
  end

  describe 'project_servers index page' do
    context 'project_servers list' do
      scenario 'when does not user has any project_server permissions' do
        visit project_servers_path

        expect(page).not_to have_css('#project_servers')
        expect(page).not_to have_content(project_server.name)
      end

      scenario 'when user has "list project_servers" permission user can view project_servers list' do
        permissions << view_project_servers_permission
        visit project_servers_path

        expect(current_path).to eq project_servers_path
        expect(page).to have_css('#project_servers')
        expect(page).to have_content(project_server.name)
      end
    end

    context '"Create new Integration" button' do
      background do
        permissions << view_project_servers_permission
      end

      scenario 'when does not user has any project_server permissions except view list' do
        visit project_servers_path
        expect(page).not_to have_css('.create_project_server')

        visit new_project_server_path
        expect(page).not_to have_content('Create new Integration')
      end

      scenario 'when user has "create project_server" permission user can see "Create new Integration" button' do
        permissions << create_project_server_permission
        visit project_servers_path

        expect(page).to have_css('.create_project_server')
        page.find('.create_project_server').click
        expect(page).to have_css('.create_server')
      end
    end

    context '"Edit" link' do
      background do
        permissions << view_project_servers_permission
      end

      scenario 'when does not user has any project_server permissions except view list' do
        visit project_servers_path
        expect(page).not_to have_css('.edit_project_server')

        visit edit_project_server_path(project_server)
        expect(page).not_to have_content(project_server.name)
      end

      scenario 'when user has "edit project_server" permission user can see "Edit" link' do
        permissions << edit_project_server_permission
        visit project_servers_path

        expect(page).to have_css('.edit_project_server')
        page.find("#project_server_#{ project_server.id } .edit_project_server").click
        expect(page).to have_content(project_server.name)
      end
    end

    context '"Manage projects" link' do
      background do
        permissions << view_project_servers_permission
      end

      scenario 'when does not user has any project_server permissions except view list' do
        visit project_servers_path
        expect(page).not_to have_css('.manage_integration_project')
      end

      scenario 'when user has "edit project_server" permission user can see "Manage Projects link' do
        permissions << edit_integration_project_permission
        visit project_servers_path

        expect(page).to have_link 'Manage Projects'
        click_on_manage_project_link(project_server)
        expect(page).to have_css('#integration_projects')
      end

      scenario 'is visible and by click opens a page that has an add project button' do
        permissions << create(:permission, permissions_list.permission('Create Integration Project'))
        visit project_servers_path

        expect(page).to have_link 'Manage Projects'
        click_on_manage_project_link(project_server)
        expect(page).to have_link 'Add Project'
      end
    end

    context '"Make active/inactive" link' do
      background do
        permissions << view_project_servers_permission
      end

      scenario 'when does not user has any project_server permissions except view list' do
        visit project_servers_path
        expect(page).not_to have_css('.make_inactive_project_server')
        expect(page).not_to have_content('Inactive')
      end

      scenario 'when user has "make default project_server" permission user can see "Make Default" link' do
        permissions << make_inactive_project_server_permission
        visit project_servers_path

        expect(page).to have_css('.make_inactive_project_server')
        page.find("#project_server_#{ project_server.id } .make_inactive_project_server").click
        expect(page).to have_content('Inactive')
      end
    end
  end

  def click_on_manage_project_link(project_server)
    page.find("#project_server_#{ project_server.id } .manage_integration_project").click
  end
end

