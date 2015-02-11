require 'spec_helper'

feature 'User updates an overridden property', js: true do
  scenario 'and the changes are reflected in the list' do
    sign_in create(:old_user)
    property = create(:property)
    package = create(:package, properties: [property])
    reference = create(:reference, package: package)
    property_value = create(:property_value, value_holder: reference, value: 'My Value')
    visit edit_package_reference_path(package, reference)

    update_property_value('Updated value')

    within '.overridden-properties' do
      expect(page).to have_content('Updated Value')
    end
  end

  def update_property_value(new_property_value)
    within '.overridden-properties' do
      click_on 'Edit'
    end
    fill_in 'Value', with: 'Updated Value'
    click_on 'Update Property'
  end
end
