require 'spec_helper'

feature 'Complex package permissions', js: true, custom_roles: true do
  given(:user) { create_non_admin_user }
  given(:allowed_app) { create_app_with_packages_for_user(user) }
  given(:disallowed_app) { create_app_with_packages_for_user(user) }

  scenario "allows editing of one app's packages and not the other" do
    user_has_permissions_to_app(allowed_app)
    user_has_no_permissions_to_app(disallowed_app)

    sign_in user

    visit packages_path

    allowed_app.packages.each do |package|
      expect(package_row(package)).to have_an_edit_link_to(package)
      expect(package_row(package)).to have_link(instances_link)
    end

    disallowed_app.packages.each do |package|
      expect(package_row(package)).to_not have_an_edit_link_to(package)
      expect(package_row(package)).to_not have_link(instances_link)
    end
  end

  def create_non_admin_user
    # The first user in the database becomes admin. This prevents that.
    user = create(:user)
    user.groups = []
    user
  end

  def user_has_permissions_to_app(app)
    granter = TestPermissionGranter.new(app.teams.first.groups.first.roles.first.permissions)
    granter << "Environment" << "View Packages List" << "Edit Package" << 'View Package Instances List'
  end

  def user_has_no_permissions_to_app(app)
    app.teams.first.groups.first.roles.first.permissions = []
  end

  def create_app_with_packages_for_user(user)
    app = create_app_for_user(user)
    create_packages_for_app(app)
    app
  end

  def create_app_for_user(user)
    app = create(:app)
    team = create(:team)
    group = create(:group)
    role = create(:role)
    app.teams = [team]
    app.users = [user]
    user.groups << group
    team.groups = [group]
    group.roles = [role]
    app
  end

  def create_packages_for_app(app)
    [create_package_for_app(app), create_package_for_app(app)]
  end

  def create_package_for_app(app)
    create(:application_package, app: app, package: create(:package)).package
  end

  def have_an_edit_link_to(package)
    have_css("a", text: package.name)
  end

  def instances_link
    I18n.t('package.instances')
  end

  def package_row(package)
    find("#package_#{package.id}")
  end

end

