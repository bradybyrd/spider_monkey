require 'spec_helper'

feature 'Bulk delete request', custom_roles: true, js: true do
  scenario 'can be accessed by non root user with all permissions' do
    user = given_user_with_permissions_to_bulk_delete_requests
    sign_in user
    visit settings_path

    click_link 'Bulk Delete Requests'

    expect(page).not_to have_no_access_message
  end

  def given_user_with_permissions_to_bulk_delete_requests
    user = create(:user, :with_role_and_group)
    permissions = TestPermissionGranter.new(user.groups.first.roles.first.permissions)
    permissions << 'View General' << 'Delete Request' << 'View Requests list'

    user
  end

  def have_no_access_message
    have_content(I18n.t(:'activerecord.errors.no_access_to_view_page'))
  end
end
