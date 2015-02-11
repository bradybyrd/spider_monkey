require 'spec_helper'
require 'cancan/matchers'

feature 'user permissions page', custom_roles: true do
  given!(:user)         { create(:old_user, :not_admin_with_role_and_group, login: 'delete_if_this_fails') }
  given!(:permissions)  { user.groups.first.roles.first.permissions }
  given!(:permission_to) do
    {
        user: {
            list:           create(:permission, subject: 'User', action: 'list', name: 'List User'),
            create:         create(:permission, subject: 'User', action: 'create', name: 'Create User'),
            edit:           create(:permission, subject: 'User', action: 'edit', name: 'Edit User'),
            make_active_inactive:  create(:permission, subject: 'User', action: 'make_active_inactive', name: 'Make Inactive User')
        },
        system_tab: {
            view:           create(:permission, subject: 'system_tab', action: 'view', name: 'view system_tab')
        }
    }
  end

  background do
    permissions << permission_to[:system_tab][:view]
    login_as user
  end

  context 'user without list permission for User page' do
    scenario 'user will not see list of users' do
      visit users_path

      expect(current_path).to eq users_path
      expect(page).not_to have_css('div#active_users')
    end
  end

  context 'user without create permission for User page' do
    scenario 'user will not see the Add New User button' do
      permissions << permission_to[:user][:list]

      visit users_path

      expect(current_path).to eq users_path
      expect(page).not_to have_link('Add New User')
    end
  end

  context 'user without edit permission for User page' do
    scenario 'user will not be able to edit user' do
      permissions << permission_to[:user][:list]

      visit users_path

      within('#active_users') do
        expect(page).to  have_content("#{user.name_for_index}")
        expect(page).not_to have_link("#{user.name_for_index}")
      end
    end
  end

end
