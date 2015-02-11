require 'spec_helper'

feature 'Simple package permissions', js: true, custom_roles: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given!(:active_package) { create(:package) }
  given!(:inactive_package) { create(:package, active: false) }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    User.stub(:current_user).and_return(user)
    permissions << "Environment" << "View Environments list"
    app = create(:app)
    create(:team_with_apps_and_groups, apps: [app], groups: user.groups)
    create(:application_package, app: app, package: active_package)
    create(:application_package, app: app, package: inactive_package)
    sign_in user
  end

  describe 'make tabs' do
    scenario 'not available if permissions disallow' do
      visit environments_path

      within '.drop_down.environments' do
        expect(page).to have_no_link 'Packages'
      end

      within '.pageSection ul' do
        expect(page).to have_no_link 'Packages'
      end
    end

    scenario 'available if permissions allow' do
      permissions << "View Packages List"
      visit environments_path

      within '.drop_down.environments' do
        expect(page).to have_link 'Packages'
      end

      within '.pageSection ul' do
        expect(page).to have_link 'Packages'
      end
    end
  end

  describe 'while viewing' do
    before { permissions << "View Packages List" }

    scenario 'allow only viewing with list permission' do
      visit packages_path

      within '.Right #sidebar' do
        expect(page).to have_no_link 'Add a new package'
      end

      within '#active_table' do
        expect(page).to have_no_content 'Edit'
        expect(page).to have_no_content 'Make Inactive'
        expect(page).to have_no_link active_package.name
      end

      within '#inactive_table' do
        expect(page).to have_no_content 'Make Active'
        expect(page).to have_no_link inactive_package.name
      end
    end

    scenario 'allow anything with manage permission' do
      permissions << "Create Package" << "Edit Package" << "Delete Package" << "Make Inactive/Active Package"
      visit packages_path

      within '.Right #sidebar' do
        expect(page).to have_link 'Add a new package'
      end

      within '#active_table' do
        expect(page).to have_link 'Edit'
        expect(page).to have_link active_package.name
      end

      within '#inactive_table' do
        expect(page).to have_link 'Make Active'
        expect(page).to have_link inactive_package.name
      end
    end
  end
end
