require 'spec_helper'

feature 'User overrides a property for a reference', js: true do
  scenario 'and the overridden property is shown on the page' do
    sign_in create(:old_user)
    property = create(:property)
    package = create(:package, properties: [property])
    reference = create(:reference, package: package)
    visit edit_package_reference_path(package, reference)

    click_on 'Override a property'
    fill_in 'Value', with: 'Overridden Value'
    click_on 'Create Property'

    within '.overridden-properties' do
      expect(page).to have_content(property.name)
      expect(page).to have_content('Overridden Value')
    end
  end
end
