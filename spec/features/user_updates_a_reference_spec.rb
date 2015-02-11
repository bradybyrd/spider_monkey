require 'spec_helper'

feature 'User updates a reference', js: true do
  scenario 'they are redirected to the package and the reference is updated' do
    sign_in create(:old_user)
    package = create(:package)
    server = create(:server)
    reference = create(:reference, package: package, server: server)
    populate_server_list_with(server)
    visit edit_package_reference_path(package, reference)

    fill_in_reference_form(name: 'Great Reference', server: server.name, uri: 'My URI')
    click_on 'Update Reference'

    expect(current_path).to eq edit_package_path(package)
    expect(references_table).to have_reference_with('My URI')
    expect(references_table).to have_reference_with('Great Reference')
    expect(references_table).to have_reference_with(server.name)
  end

  def references_table
    find('.references')
  end

  def have_reference_with(property_value)
    have_css('.property_row td', text: property_value)
  end
end
