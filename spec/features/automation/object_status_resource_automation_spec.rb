require 'spec_helper'

feature 'Automation scripts page has object status', js: true do
  given!(:user) { create(:user, :root) }
  given!(:resource_automation_script) { create(:resource_automation_script, aasm_state: 'draft') }

  background do
    allow(GlobalSettings).to receive(:automation_enabled?).and_return(true)
    sign_in user
  end

  scenario 'changing states on list page' do
    visit automation_scripts_path

    expect(page).to have_content(resource_automation_script.name)
    expect(page).to have_state('Draft')
    expect(page).to_not have_link('Delete', href: script_path(resource_automation_script))

    move_state_right
    expect(page).to have_state('Pending')
    expect(page).to_not have_link('Delete', href: script_path(resource_automation_script))

    move_state_right
    expect(page).to have_state('Released')
    expect(page).to_not have_link('Delete', href: script_path(resource_automation_script))

    move_state_right
    expect(page).to have_state('Retired')
    expect(page).to_not have_link('Delete', href: script_path(resource_automation_script))

    move_state_right
    expect(page).to have_archived_state
    expect(page).to have_link('Delete', href: script_path(resource_automation_script))

    click_on 'Unarchive'
    expect(page).to have_state('Retired')
  end

  def move_state_right
    within "#state_list_#{ resource_automation_script.id }" do
      click_on '>>'
    end
  end

  def have_state(state)
    have_css("#td_state_#{ resource_automation_script.id }", text: state)
  end

  def have_archived_state
    have_content(resource_automation_script.name + ' [archived')
  end
end
