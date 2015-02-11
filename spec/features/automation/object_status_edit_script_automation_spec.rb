require 'spec_helper'

feature 'User edits an automation script', js: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }
  given!(:general_script) { create(:general_script, aasm_state: 'released', created_by: user.id) }

  background do
    permissions << 'View Automation list' << 'Edit Automation'
    allow(GlobalSettings).to receive(:automation_enabled?).and_return(true)
    sign_in user
  end

  scenario 'authorized and the edit page shows the state of the script' do
    permissions << 'Update Automation State'

    visit automation_scripts_path
    click_on 'Edit'
    wait_for_ajax

    expect(page).to have_change_state_control('Released')
    move_state_right
    wait_for_ajax
    expect(page).to have_change_state_control('Retired')
  end

  scenario 'not authorized and cannot change the state of the script' do

    visit automation_scripts_path

    click_on 'Edit'
    wait_for_ajax

    expect(page).not_to have_change_state_control('Released')
  end

  def have_change_state_control(state)
    have_css("#state_indicator li.active", text: state)
  end

  def move_state_right
    within "#state_indicator" do
      click_on '>>'
    end
  end
end
