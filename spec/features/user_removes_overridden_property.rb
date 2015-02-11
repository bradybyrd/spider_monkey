require 'spec_helper'

feature 'User removes an overridden property', js: true do
  scenario 'and the property is removed from the list' do
    sign_in create(:old_user)
    property = create(:property)
    package = create(:package, properties: [property])
    reference = create(:reference, package: package)
    property_value = create(:property_value, value_holder: reference, value: 'My Value')
    visit edit_package_reference_path(package, reference)

    within '.overridden-properties' do
      click_on 'Remove'
    end

    expect(page).not_to have_content('My Value')
    expect(page).to have_content('Overridden property was deleted')
  end
end
