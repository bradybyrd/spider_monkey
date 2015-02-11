require 'spec_helper'

feature 'Package instance permissions', js: true, custom_roles: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given!(:package) { create(:package) }
  given!(:active_package_instance) { create(:package_instance, package: package) }
  given!(:inactive_package_instance) { create(:package_instance, package: package, active: false) }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    User.stub(:current_user).and_return(user)
    permissions << "Environment" << "View Packages List" << "View Package Instances List"
    app = create(:app)
    create(:team_with_apps_and_groups, apps: [app], groups: user.groups)
    create(:application_package, app: app, package: package)
    sign_in user
  end

  scenario 'with list permission' do
    visit packages_path
    expect(page).to have_link_to_package_instances
    view_package_instances
    expect(page).to have_instance_in_list_named(active_package_instance.name)
  end

  scenario 'with create/edit permission' do
    permissions << "Create Instance" << "Edit Instance"

    visit packages_path
    view_package_instances
    packages_instance_name = create_new_package_instance
    expect(page).to have_instance_in_list_named(packages_instance_name)
  end

  scenario "with active/inactive permission" do
    permissions << "Make Inactive/Active Instance"

    visit packages_path
    view_package_instances
    activate_package_instance
    expect(page).to have_made_inactive_package_instance_active
  end

  scenario "with delete permission" do
    permissions << "Delete Instance"

    visit packages_path
    view_package_instances
    expect(page).to be_able_to_delete_inactive_package
  end

  def have_link_to_package_instances
    have_css("#active_table a", text: "Instances")
  end

  def view_package_instances
    within("#active_table") do
      click_on("Instances")
    end
  end

  def have_instance_in_list_named(package_instance_name)
    have_css("#active_table td", text: package_instance_name)
  end

  def create_new_package_instance
    within("#sidebar") do
      click_on("Add a new package instance")
    end
    name = SecureRandom.uuid
    fill_in "Name", with: name
    click_on("Create")
    click_on("cancel")
    name
  end

  def activate_package_instance
    within("#inactive_table") do
      click_on("Make Active")
    end
  end

  def have_made_inactive_package_instance_active
    have_css("#active_table", text: inactive_package_instance.name)
  end

  def be_able_to_delete_inactive_package
    have_css("#inactive_table", text: "Delete")
  end

end
