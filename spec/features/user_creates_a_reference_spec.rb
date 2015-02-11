require 'spec_helper'

feature 'User creates a reference' do
  scenario 'and the reference appears on the edit package page', js: true do
    sign_in create(:old_user)
    package = create(:package)
    server = create(:server)
    populate_server_list_with(server)
    visit edit_package_path(package)

    click_on 'Add Reference'
    fill_in_reference_form(name: 'Great Reference', server: server.name, uri: 'My URI')
    click_on 'Create Reference'

    expect(page).to have_field 'Uri', with: 'My URI'
    expect(page).to have_field 'Name', with: 'Great Reference'
    expect(page).to have_select 'Server', selected: server.name
  end
end
