require 'spec_helper'

feature 'Groups page permissions', custom_roles: true do
  given!(:user) { create(:old_user, :not_admin_with_role_and_group) }
  given!(:group) { create(:group) }
  given!(:basic_permissions) { [
      create(:permission, name: 'View applications', action: :view, subject: :my_applications ),
      create(:permission, name: 'View dashboard tab', action: :view, subject: :dashboard_tab ),
      create(:permission, name: 'System tab view', action: :view, subject: :system_tab)
    ] }

  given(:permissions) { user.groups.first.roles.first.permissions }

  given(:view_groups_permission) { create(:permission, name: 'View groups list', action: :list, subject: 'Group') }
  given(:create_group_permission) { create(:permission, name: 'Create group', action: :create, subject: 'Group') }
  given(:edit_group_permission) { create(:permission, name: 'Edit group', action: :edit, subject: 'Group') }
  given(:make_default_group_permission) { create(:permission, name: 'Make default group', action: :make_default, subject: 'Group') }
  given(:make_inactive_group_permission) { create(:permission, name: 'Make active/inactive group', action: :make_active_inactive, subject: 'Group') }

  background do
    permissions << basic_permissions

    sign_in user
  end

  describe '"Group" tab' do
    scenario 'not available when user hasn"t "list groups" permission' do
      visit groups_path

      within '#primaryNav' do
        expect(page).to have_no_content 'Groups'
      end

      within '.pageSection ul' do
        expect(page).to have_no_content 'Groups'
      end
    end

    scenario 'available when user has "list groups" permission' do
      permissions << view_groups_permission
      visit groups_path

      within '#primaryNav' do
        expect(page).to have_link 'Groups'
      end

      within '.pageSection ul' do
        expect(page).to have_link 'Groups'
      end
    end
  end

  describe 'groups index page' do
    context 'groups list' do
      scenario 'when does not user has any group permissions' do
        visit groups_path

        expect(page).not_to have_css('#groups')
        expect(page).not_to have_content(group.name)
      end

      scenario 'when user has "list groups" permission user can view groups list' do
        permissions << view_groups_permission
        visit groups_path

        expect(page).to have_css('#groups')
        expect(page).to have_content(group.name)
      end
    end

    context '"Create Group" button' do
      background do
        permissions << view_groups_permission
      end

      scenario 'when does not user has any group permissions except view list' do
        visit groups_path
        expect(page).not_to have_css('.create_group')

        visit new_group_path
        expect(page).not_to have_content('Create Resource Group')
      end

      scenario 'when user has "create group" permission user can see "Create group" button' do
        permissions << create_group_permission
        visit groups_path

        expect(page).to have_css('.create_group')
        page.find('.create_group').click
        expect(page).to have_content('Create Resource Group')
      end
    end

    context '"Edit Group" link' do
      background do
        permissions << view_groups_permission
      end

      scenario 'when does not user has any group permissions except view list' do
        visit groups_path
        expect(page).not_to have_css('.edit_group')

        visit edit_group_path(group)
        expect(page).not_to have_content(group.name)
      end

      scenario 'when user has "edit group" permission user can see "Edit" link' do
        permissions << edit_group_permission
        visit groups_path

        expect(page).to have_css('.edit_group')
        page.find("#group_#{ group.id } .edit_group").click
        expect(page).to have_content(group.name)
      end
    end

    context '"Make Default" link' do
      background do
        permissions << view_groups_permission
      end

      scenario 'when does not user has any group permissions except view list' do
        visit groups_path
        expect(page).not_to have_css('.make_default_group')
      end

      scenario 'when user has "make default group" permission user can see "Make Default" link' do
        permissions << make_default_group_permission
        visit groups_path

        expect(page).to have_css('.make_default_group')
        page.find("#group_#{ group.id } .make_default_group").click
        expect(page).to have_content('Resource Group was successfully updated')
      end
    end

    context '"Make active/inactive" link' do
      background do
        permissions << view_groups_permission
      end

      scenario 'when does not user has any group permissions except view list' do
        visit groups_path
        expect(page).not_to have_css('.make_inactive_group')
        expect(page).not_to have_content('Inactive')
      end

      scenario 'when user has "make default group" permission user can see "Make Default" link' do
        permissions << make_inactive_group_permission
        visit groups_path

        expect(page).to have_css('.make_inactive_group')
        page.find("#group_#{ group.id } .make_inactive_group").click
        expect(page).to have_content('Inactive')
      end
    end
  end

end
