require 'spec_helper'

feature 'Application Package Tab', js: true, custom_roles: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group, apps: [application]) }
  given!(:application_package) { create(:application_package, :with_properties) }
  given(:application) { application_package.app }
  given!(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    permissions << "Add/Remove Package" << "Edit Package Properties" << "Inspect Application"
    create(:team_with_apps_and_groups, apps: [application], groups: user.groups)
    sign_in user
  end

  describe 'Application edit page' do
    scenario 'displays application packages table' do
      visit app_path(application)
      open_packages_tab

      expect(packages_list_first_row_cell(1)).to have_text(application_package.position.to_s)
      expect(packages_list_first_row_cell(2)).to have_text(application_package.package.name)
    end
  end


  def packages_list_first_row_cell(cellNum)
    find("#packages_list > tbody > tr:nth-child(1) > td:nth-child(#{cellNum})")
  end

  def open_packages_tab
    within('.component_tabs') { click_link 'Packages' }
  end
end
