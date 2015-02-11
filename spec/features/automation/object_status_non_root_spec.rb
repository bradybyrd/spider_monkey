require 'spec_helper'

feature 'Automation scripts page has object status', js: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }
  given!(:automation_script) { create(:general_script,  aasm_state: 'draft',created_by: user.id) }

  background do
    permissions << 'View Automation list' << 'Edit Automation'
    allow(GlobalSettings).to receive(:automation_enabled?).and_return(true)
    sign_in user
  end

  scenario 'changing states on list page as a non root user' do
    permissions << 'Update Automation State'

    visit automation_scripts_path

    expect(page).to have_content(automation_script.name)
    expect(page).to have_state('Draft')

    move_state_right
    expect(page).to have_state('Pending')

    move_state_right
    expect(page).to have_state('Released')

    move_state_right
    expect(page).to have_state('Retired')

    move_state_right
    expect(page).to have_archived_state

    click_on 'Unarchive'
    expect(page).to have_state('Retired')
  end

  def move_state_right
    within "#state_list_#{ automation_script.id }" do
      click_on '>>'
    end
  end

  def have_state(state)
    have_css("#td_state_#{ automation_script.id }", text: state)
  end

  def have_archived_state
    have_content(automation_script.name + ' [archived')
  end
end
