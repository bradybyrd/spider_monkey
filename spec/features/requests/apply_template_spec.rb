require 'spec_helper'

feature 'A user visits Apply Template page', js: true, custom_roles: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }
  given!(:request) { create(:request, :with_assigned_app, user: user) }

  scenario 'with Choose Template permission' do
    User.stub(:current_user).and_return(user)
    permissions << 'View Requests list' << 'View created Requests list' << 'Inspect Request' << 'Apply Template' << 'Choose Template'

    sign_in user
    visit request_path(request)
    click_on 'Apply Template'

    expect(page).to have_link('Btn-choose-template')
  end

  scenario 'without Choose Template permission' do
    User.stub(:current_user).and_return(user)
    permissions << 'View Requests list' << 'View created Requests list' << 'Inspect Request' << 'Apply Template'

    sign_in user
    visit request_path(request)
    click_on 'Apply Template'

    expect(page).not_to have_link('Btn-choose-template')
  end
end