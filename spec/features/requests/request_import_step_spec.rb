require 'spec_helper'

feature 'Create new request step', js: true do
  scenario 'Click "Import steps" on request page' do
    user = create(:user)
    request = create(:request_with_app)

    sign_in user
    visit request_path(request)

    click_link 'Import Steps'

    expect(page).to have_content('Acceptable fields are: name, description, component, assigned_to, estimate, automation')
  end

end
