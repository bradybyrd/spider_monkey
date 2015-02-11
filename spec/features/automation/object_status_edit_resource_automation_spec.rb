require 'spec_helper'

feature 'User edits an resource automation script', js: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }
  given!(:resource_automation_script) { create(:resource_automation_script, aasm_state: 'released') }

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
  end

  scenario 'not authorized and cannot change the state of the script' do
    visit automation_scripts_path
    click_on 'Edit'
    wait_for_ajax

    expect(page).not_to have_change_state_control('Released')
  end

  scenario 'update a resource automation script with new name from script name link' do
    visit automation_scripts_path
    click_on resource_automation_script.name
    wait_for_ajax

    new_script_name = 'new_script_name_1'
    page.fill_in('script_name', with: new_script_name)
    click_on 'Update script'
    wait_for_ajax

    expect(page).to have_link(new_script_name)
  end

  scenario 'update a resource automation script with new name from Edit button' do
    visit automation_scripts_path
    click_on 'Edit'
    wait_for_ajax

    new_script_name = 'new_script_name_2'
    page.fill_in('script_name', with: new_script_name)
    click_on 'Update script'
    wait_for_ajax

    expect(page).to have_link(new_script_name)
  end

  def have_change_state_control(state)
    have_css("#state_indicator li.active", text: state)
  end
end
