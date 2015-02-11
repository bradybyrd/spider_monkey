require 'spec_helper'

feature 'Test package validations' do
  given!(:user) {create(:user, :root)}
  given!(:package) {create(:package)}

  background do
    sign_in user
  end

  describe 'display package name' do
    scenario "updates the package with valid name" do
      visit edit_package_path(package.id)

      new_package_name = 'Updated Package Name'

      fill_in "Name", with: new_package_name

      click_button "Update"

      expect(page).to have_text(new_package_name)
    end

    scenario "does not update the package with invalid name" do
      visit edit_package_path(package.id)

      new_package_name = 'a' * 256

      fill_in "Name", with: new_package_name

      click_button "Update"

      expect(page).not_to have_text(new_package_name)
      expect(page).to have_text('Name is too long')
      expect(title).to have_text(package.name_was)
    end
  end
end