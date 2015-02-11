require 'spec_helper'

feature 'User on applications list page', custom_roles: true, js: true do
  given!(:user) { create(:user, :with_role_and_group, apps: [app]) }
  given!(:app) { create(:app, :with_installed_component) }
  given!(:team) { create(:team, groups: user.groups) }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    create(:development_team, team: team, app: app)
    permissions << 'View Applications list' << 'Inspect Application' << 'Applications'

    sign_in user
  end

  context 'edit application link in apps list' do
    scenario 'can see edit link' do
      permissions << 'Edit Application'
      visit apps_path
      expect(page).to have_edit_link
    end

    scenario 'cannot see edit link' do
      visit apps_path
      expect(page).not_to have_edit_link
    end
  end

  def have_edit_link
    have_link 'Edit'
  end
end
