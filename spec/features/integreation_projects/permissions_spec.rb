require 'spec_helper'

feature 'IntegrationProjects page permissions', custom_roles: true do
  given!(:user) { create(:old_user, :not_admin_with_role_and_group) }
  given!(:integration_project) { create(:integration_project) }
  given!(:basic_permissions) { [
      create(:permission, name: 'View applications', action: :view, subject: :my_applications),
      create(:permission, name: 'View dashboard tab', action: :view, subject: :dashboard_tab),
      create(:permission, name: 'System tab view', action: :view, subject: :system_tab)
  ] }

  given(:permissions) { user.groups.first.roles.first.permissions }

  given(:create_integration_project_permission) { create(:permission, name: 'Create integration project', action: :create, subject: 'IntegrationProject') }
  given(:edit_integration_project_permission) { create(:permission, name: 'Edit integration project', action: :edit, subject: 'IntegrationProject') }
  given(:make_inactive_integration_project_permission) { create(:permission, name: 'Make active/inactive integration project', action: :make_active_inactive, subject: 'IntegrationProject') }

  background do
    permissions << basic_permissions

    sign_in user
  end

  describe '"IntegrationProjects" page' do
    context '"Create Project" button' do
      background do
        permissions << edit_integration_project_permission
      end

      scenario 'when does not user has any integration_project permissions except view list' do
        visit project_server_integration_projects_path(integration_project.project_server)
        expect(page).not_to have_css('.create_integration_project')

        visit new_project_server_integration_project_path(integration_project.project_server)
        expect(page).not_to have_content('Create Project')
      end

      scenario 'when user has "create integration_project" permission user can see "Create new Integration" button' do
        permissions << create_integration_project_permission
        visit project_server_integration_projects_path(integration_project.project_server)

        expect(page).to have_css('.create_integration_project')
        page.find('.create_integration_project').click
        expect(page).to have_css('.save_integration_project')
      end
    end

    context '"Edit Project Server" link' do
      scenario 'when user has "edit integration_project" permission user can see "Edit" link' do
        permissions << edit_integration_project_permission

        visit project_server_integration_projects_path(integration_project.project_server)

        expect(page).to have_css('.edit_integration_project')
        page.find("#integration_project_#{ integration_project.id } .edit_integration_project").click
        expect(page).to have_content(integration_project.name)
      end

      scenario 'when user has not "edit integration_project" permission user cannot see "Edit" link' do
        permissions << create_integration_project_permission

        visit project_server_integration_projects_path(integration_project.project_server)

        expect(integration_projects_list).to have_text(integration_project.name)
        expect(integration_projects_list).not_to have_link(I18n.t(:edit))
      end
    end

    context '"Make active/inactive" link' do
      background do
        permissions << edit_integration_project_permission
      end

      scenario 'when does not user has any integration_project permissions except view list' do
        visit project_server_integration_projects_path(integration_project.project_server)
        expect(page).not_to have_css('.make_inactive_integration_project')
        expect(page).not_to have_content('Inactive')
      end

      scenario 'when user has "make default integration_project" permission user can see "Make Default" link' do
        permissions << make_inactive_integration_project_permission
        visit project_server_integration_projects_path(integration_project.project_server)

        expect(page).to have_css('.make_inactive_integration_project')
        page.find("#integration_project_#{ integration_project.id } .make_inactive_integration_project").click
        expect(page).to have_content('Inactive')
      end
    end
  end

  def integration_projects_list
    find('#integration_projects')
  end

end
