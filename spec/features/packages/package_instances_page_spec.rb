require 'spec_helper'

feature 'Package instances display', js: true do

  given!(:user) { create(:user, :root) }
  given!(:package) { create(:package) }
  given!(:package_instance) { create(:package_instance, package: package) }

  background do
    sign_in user
  end

  scenario '"not used" label and "Make Inactive" link show up for unused package instance' do
    visit package_instances_path(package)
    expect(page).to have_not_used_label
    expect(page).to have_make_inactive_link
  end

  def have_not_used_label
    have_text('not used')
  end

  def have_make_inactive_link
    have_link('Make Inactive')
  end

  scenario '"not used" label and "Make Inactive" link do not show up for used package instance' do
    app = create(:app, :with_installed_component)
    app.packages = [package]
    request = create(:request, apps:[app], environment: app.environments.last)
    step = create(:step, request: request)
    step.related_object_type = "package"
    step.package = package
    step.package_instance = package_instance
    step.save!

    visit package_instances_path(package)
    expect(page).to_not have_not_used_label
    expect(page).to_not have_make_inactive_link
  end

end
