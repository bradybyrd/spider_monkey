require 'spec_helper'

feature 'Request permissions in the context of Package Instance', js: true, custom_roles: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }
  given!(:team) { create(:team, groups: user.groups) }

  scenario 'with View Requests List permission' do
    User.stub(:current_user).and_return(user)
    permissions << "View Packages List" << "View Package Instances List" << "View Requests list"

    active_package_instance = create_package_instance

    sign_in user
    visit packages_path
    expect(page).to have_link_to_package_instances
    view_package_instances
    expect(page).to have_content(active_package_instance.recent_activity.first.number)
    expect(page).not_to have_link(active_package_instance.recent_activity.first.number)
  end

  scenario 'with Inspect Request permission' do
    User.stub(:current_user).and_return(user)
    permissions << "View Packages List" << "View Package Instances List" << "View Requests list" << "Inspect Request"

    active_package_instance = create_package_instance

    sign_in user
    visit packages_path
    expect(page).to have_link_to_package_instances
    view_package_instances
    expect(page).to have_link(active_package_instance.recent_activity.first.number)
  end

  scenario 'without View Requests List permission' do
    User.stub(:current_user).and_return(user)
    permissions << "View Packages List" << "View Package Instances List"

    active_package_instance = create_package_instance

    sign_in user
    visit packages_path
    expect(page).to have_link_to_package_instances
    view_package_instances
    expect(page).not_to have_link(active_package_instance.recent_activity.first.number)
    expect(page).not_to have_content(active_package_instance.recent_activity.first.number)
  end

private
  def create_package_instance
    env = create(:environment)
    app = create(:app, environments: [env])
    team.apps << app
    package = create_package_for_app(app)
    active_package_instance = create(:package_instance, package: package, active: true)
    create(:step, package_instance: active_package_instance)
    active_package_instance
  end

  def have_link_to_package_instances
    have_css("#active_table a", text: "Instances")
  end

  def create_package_for_app(app)
    create(:application_package, app: app, package: create(:package)).package
  end

  def view_package_instances
    within("#active_table") do
      click_on("Instances")
    end
  end
end
