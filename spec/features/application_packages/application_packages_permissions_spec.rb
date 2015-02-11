require 'spec_helper'

feature 'Application Package permissions', js: true, custom_roles: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group, apps: [application]) }
  given!(:application) do
    create(:application_package, :with_properties).app
  end

  given(:permissions) { user.groups.first.roles.first.permissions }
  given(:permissions_list) { PermissionsList.new }
  given(:basic_permissions) { create(:permission, permissions_list.permission('Inspect Application')) }
  given(:managing_permissions) do
    [
      create(:permission, permissions_list.permission('Add/Remove Package')),
      create(:permission, permissions_list.permission('Edit Package Properties'))
    ]
  end

  background do
    permissions << basic_permissions
    create(:team_with_apps_and_groups, apps: [application], groups: user.groups)
    sign_in user
  end

  describe 'Application edit page' do
    context 'w/o permissions' do
      scenario 'can view application paackages' do
        visit app_path(application)
        open_packages_tab

        expect(page).not_to have_add_package_link
        expect(packages_list).not_to have_properties_link
      end
    end

    context 'with permissions' do
      scenario 'can add/remove packages, edit properties' do
        permissions << managing_permissions
        visit app_path(application)
        open_packages_tab

        expect(page).to have_add_package_link
        expect(packages_list).to have_properties_link
      end
    end
  end

  def packages_list
    find('#packages_list')
  end

  def have_add_package_link
    have_link I18n.t('packaging.add_or_remove')
  end

  def have_properties_link
    have_link 'Properties'
  end

  def open_packages_tab
    within('.component_tabs') { click_link 'Packages' }
  end
end
