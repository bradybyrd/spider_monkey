require 'spec_helper'

feature 'Package instance edit', js: true do

  given!(:user) { create(:user) }
  given!(:package) { create(:package) }
  given!(:package_instance) { create(:package_instance, package: package) }

  background do
    sign_in user
  end

  scenario 'show add references link when references empty' do
    visit edit_package_instance_path(package_instance)
    expect(page).to have_link_to_add_references
  end

  def have_link_to_add_references
    have_link('add references')
  end

end
