require 'spec_helper'

feature 'Server Groups page permissions', js: true, custom_roles: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given!(:server_group) { create(:server_group) }
  given!(:inactive_server_group) { create(:server_group, active: false) }

  given(:permissions) { user.groups.first.roles.first.permissions }

  given(:basic_permissions) do
    [
      create(:permission, name: 'Environment Tab', action: 'view', subject: 'environment_tab'),
      create(:permission, name: 'Access Servers', action: 'list', subject: 'Server')
    ]
  end

  given(:list_permission) { create(:permission, name: 'List', action: 'list', subject: 'ServerGroup') }

  given(:managing_permissions) do
    [
      create(:permission, name: 'Create', action: 'create', subject: 'ServerGroup'),
      create(:permission, name: 'Edit', action: 'edit', subject: 'ServerGroup'),
      create(:permission, name: 'Delete', action: 'delete', subject: 'ServerGroup'),
      create(:permission, name: 'Make Active/Inactive', action: 'make_active_inactive', subject: 'ServerGroup')
    ]
  end

  background do
    permissions << basic_permissions
    sign_in user
  end

  describe 'tab' do
    scenario 'not available' do
      visit servers_path

      within '.server_tabs' do
        expect(page).to have_no_link 'Server Groups'
      end
    end

    context 'with list permission' do
      scenario 'tab available' do
        permissions << list_permission
        visit servers_path

        within '.server_tabs' do
          expect(page).to have_link 'Server Groups'
        end
      end
    end

    describe 'list' do
      before { permissions << list_permission }

      scenario 'can view data only' do
        visit server_groups_path

        within '.Right #sidebar' do
          expect(page).to have_no_link 'Create_server_group'
        end

        within '#server_groups .active' do
          expect(page).to have_no_link I18n.t(:edit)
          expect(page).to have_no_link I18n.t(:make_inactive)
          expect(page).to have_no_link server_group.name
          expect(page).to have_content server_group.name
        end

        within '#server_groups .inactive' do
          expect(page).to have_no_link I18n.t(:destroy)
          expect(page).to have_no_link I18n.t(:make_active)
        end
      end

      scenario 'can manage items' do
        permissions << managing_permissions
        visit server_groups_path

        within '.Right #sidebar' do
          expect(page).to have_link 'Create_server_group'
        end

        within '#server_groups .active' do
          expect(page).to have_link I18n.t(:edit)
          expect(page).to have_link I18n.t(:make_inactive)
          expect(page).to have_link server_group.name
        end

        within '#server_groups .inactive' do
          expect(page).to have_link I18n.t(:destroy)
          expect(page).to have_link I18n.t(:make_active)
        end
      end
    end
  end

end
