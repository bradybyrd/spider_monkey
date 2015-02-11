require 'spec_helper'

feature 'Request Template with plan template has status controls', js: true do
  given!(:user) { create(:user, :root) }
  given!(:plan_stage) { create(:plan_stage) }
  given!(:plan_template) { create(:plan_template, stages: [plan_stage]) }
  given!(:request_template) { create(:request_template, aasm_state: 'draft', request: create(:request_with_app), plan_stages: [plan_stage]) }
  given!(:app) { request_template.apps.first }

  background do
    sign_in user
  end

  scenario 'changing states on list page' do

    visit request_templates_path
    expect(page).to have_content(request_template.name)
    expect(page).to have_content('Draft')

    click_on '>>'
    expect(page).to have_content('Pending')

    click_on '>>'
    expect(page).to have_content('Released')

    click_on '>>'
    expect(page).to have_content('Retired')

  end
end
