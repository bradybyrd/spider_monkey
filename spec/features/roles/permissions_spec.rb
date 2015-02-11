require 'spec_helper'

feature 'Roles page permissions', custom_roles: true do
  given!(:user) { create(:old_user, :not_admin_with_role_and_group) }
  given!(:role) { create(:role) }
  given(:group) { user.groups.first }

  given(:permissions) { TestPermissionGranter.new(group.roles.first.permissions) }
  given(:view_roles_permission) { 'View Roles list' }

  background do
    permissions << 'System'

    sign_in user
  end

  describe '"Role" tab' do
    scenario 'not available when user hasn"t "list roles" permission' do
      visit roles_path

      within '#primaryNav' do
        expect(page).to have_no_content 'Roles'
      end
    end

    scenario 'available when user has "list roles" permission' do
      permissions << view_roles_permission
      visit roles_path

      within '#primaryNav' do
        expect(page).to have_link 'Roles'
      end
    end
  end

  describe 'roles index page' do
    context 'roles list' do
      scenario 'when does not user has any role permissions' do
        visit roles_path

        expect(page).not_to have_css('#roles')
        expect(page).not_to have_content(role.name)
      end

      scenario 'when user has "list roles" permission user can view roles list' do
        permissions << view_roles_permission
        visit roles_path

        expect(page).to have_css('#roles')
        expect(page).to have_content(role.name)
        expect(page).not_to have_link(role.name)
      end
    end

    context '"Create Role" button' do
      background do
        permissions << view_roles_permission
      end

      scenario 'when does not user has any role permissions except view list' do
        visit roles_path
        expect(page).not_to have_css('.create_role')

        visit new_role_path
        expect(page).not_to have_content('Create Role')
      end

      scenario 'when user has "create role" permission user can see "Create role" button' do
        permissions << 'Create Role'
        visit roles_path

        expect(page).to have_css('.create_role')
        page.find('.create_role').click
        expect(page).to have_content('Create Role')
      end
    end

    context '"Edit Role" link' do
      background do
        permissions << view_roles_permission
      end

      scenario 'when user has permission to edit groups' do
        permissions << 'Edit Group'
        visit roles_path
        expect(page).to have_link(group.name)
      end

      scenario 'when does not user has any role permissions except view list' do
        visit roles_path
        expect(page).not_to have_css('.edit_role')
        expect(page).not_to have_link(group.name)

        visit edit_role_path(role)
        expect(page).not_to have_content(role.name)
      end

      scenario 'when user has "edit role" permission user can see "Edit" link' do
        permissions << 'Edit Role'
        visit roles_path

        expect(page).to have_css('.edit_role')
        page.find("#role_#{ role.id } .edit_role").click
        expect(page).to have_content(role.name)
      end
    end

    context '"Make active/inactive" link' do
      background do
        permissions << view_roles_permission
      end

      scenario 'when does not user has any role permissions except view list' do
        visit roles_path
        expect(page).not_to have_css('.make_inactive_role')
        expect(page).not_to have_content('Inactive')
      end

      scenario 'when user has "make default role" permission user can see "Make Default" link' do
        permissions.add_from_scope view_roles_permission, 'Make Inactive/Active'
        visit roles_path

        expect(page).to have_css('.make_inactive_role')
        page.find("#role_#{ role.id } .make_inactive_role").click
        expect(page).to have_content('Inactive')
      end
    end

    context '"Delete" link' do
      background do
        permissions << view_roles_permission
        role.deactivate!
      end

      scenario 'when does not user has any role permissions except view list' do
        visit roles_path

        expect(page).not_to have_link(I18n.t(:delete))
      end

      scenario 'when user has "make default role" permission user can see "Make Default" link' do
        permissions << 'Delete Role'

        visit roles_path

        expect(page).to have_link(I18n.t(:delete))
      end
    end
  end
end
