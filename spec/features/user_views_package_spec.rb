require 'spec_helper'

feature 'User views package' do
  scenario 'and the reference appears on the package page', js: true do
    sign_in create(:old_user)

    property = create(:property)
    package = create(:package, properties: [property])
    reference = create(:reference, package: package)
    reference.update_attributes( properties_with_values: { property.name => '123' } )

    visit edit_package_path(package)

    expect(page).to have_field 'Name', with: package.name
    expect(page).to have_text I18n.t(:"table.properties")
    expect(page).to have_text reference.name
    expect(page).to have_text "#{property.name}=123"

  end
end
