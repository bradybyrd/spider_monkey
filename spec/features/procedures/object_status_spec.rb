require 'spec_helper'

feature 'Procedures page has status', js: true do
  given!(:user) { create(:user, :root) }
  given!(:procedure) { create(:procedure, aasm_state: 'draft') }

  background do
    sign_in user
  end

  scenario 'changing states on list page' do
    visit procedures_path
    expect(page).to have_content(procedure.name)
    expect(page).to have_content('Draft')

    click_on '>>'
    expect(page).to have_content('Pending')

    click_on '>>'
    expect(page).to have_content('Released')

    click_on '>>'
    expect(page).to have_content('Retired')

    click_on '>>'
    expect(page).to have_content(procedure.name + ' [archived')
  end
end