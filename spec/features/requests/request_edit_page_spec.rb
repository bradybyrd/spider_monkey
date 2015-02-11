require 'spec_helper'

feature 'User on a edit request page', custom_roles: true, js: true do
  given!(:user)             { create(:user, :non_root, :with_role_and_group) }
  given!(:permissions)      { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  before do
    sign_in user
  end

  scenario 'not being an owner of the request can modify request w/o application assignment being changed' do
    permissions << 'Inspect Request' << 'Modify Requests Details' << 'View created Requests list'
    request = create(:request_with_app, owner: create(:user, :root))
    app = request.apps.first
    team = create(:team, groups: [user.groups.first])
    team.apps = request.apps

    visit edit_request_path(request)
    click_link I18n.t(:expand)
    click_link I18n.t('request.modify_details')
    click_button I18n.t(:update)
    visit edit_request_path(request)

    expect(page).to have_content app.name
  end
end
