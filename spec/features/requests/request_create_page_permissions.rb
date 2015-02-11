require 'spec_helper'

feature 'User on a create request page', custom_roles: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given!(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    permissions << 'Create Requests'
    sign_in user
  end

  context 'with appropriate permissions' do
    scenario 'can see "Start Automatically?" check box' do
      permissions << 'Start Automatically'

      visit new_request_path

      expect(page).to have_auto_start_check_box
    end
  end

  context 'regardless permissions' do
    scenario 'cannot see "Start Automatically?" check box' do
      visit new_request_path

      expect(page).not_to have_auto_start_check_box
    end
  end

  def have_auto_start_check_box
    have_css '#request_auto_start'
  end
end
