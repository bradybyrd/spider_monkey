require 'spec_helper'

feature 'User on application page', custom_roles: true, js: true do
  given!(:user) { create(:user, :with_role_and_group, apps: [app]) }
  given!(:app) { create(:app, :with_installed_component) }
  given!(:team) { create(:team, groups: user.groups) }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    create(:development_team, team: team, app: app)
    permissions << 'View Applications list' << 'Inspect Application' << 'Applications' << 'Export Application'

    sign_in user
  end

  describe '"Export Application" link' do
    scenario 'exists for active application' do
      visit app_path(app)

      expect(page).to have_link ('Export Application')
    end

    scenario 'does not exist with inactive application' do
      app.update_attributes(active: false)

      visit app_path(app)

      expect(page).not_to have_link ('Export Application')
    end

  end
end
