require 'spec_helper'

feature 'Procedures page has status', js: true do
  given!(:user) { create(:user, :non_root,:with_role_and_group) }
  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }
  given!(:procedure) { create(:procedure, aasm_state: 'draft',created_by: user.id) }

  background do
    permissions << 'View Procedures list' << 'Edit Procedures'
    sign_in user
  end

  scenario 'changing states on list page' do
    permissions << 'Update Procedures State'

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