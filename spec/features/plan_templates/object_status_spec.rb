require 'spec_helper'

feature 'Plan Templates page has state', js: true do
  scenario 'changing states on list page' do
    user = create(:user, :root)
    plan_template = create(:plan_template, aasm_state: 'draft')
    sign_in user

    visit plan_templates_path
    expect(page).to have_content(plan_template.name)
    expect(page).to have_content('Draft')

    advance_state
    expect(page).to have_content('Pending')

    advance_state
    expect(page).to have_content('Released')

    advance_state
    expect(page).to have_content('Retired')

    advance_state
    expect(page).to have_content(plan_template.name + ' [archived')
  end

  scenario "visible even when user does not have permission to change state" do
    user = create(:user, :with_role_and_group)
    permissions = permissions_for(user)
    permissions << everything_but_update_state
    plan_template = create(:plan_template, aasm_state: 'retired')
    sign_in user
    visit plan_templates_path
    click_on(plan_template.name)

    expect(page).to_not be_able_to_advance_state
    expect(plan_template_state).to be_retired
  end

  def advance_state
    within(".state_list") do
      click_on '>>'
    end
  end

  def permissions_for(user)
    TestPermissionGranter.new(user.groups.first.roles.first.permissions)
  end

  def everything_but_update_state
    [
      "Environment",
      "Access Metadata",
      "View Plan Templates list",
      "Inspect Plan Templates",
      "Create Plan Templates",
      "Edit Plan Templates",
      "Delete Plan Templates"
    ]
  end

  def be_able_to_advance_state
    have_css(".state_transition a")
  end

  def plan_template_state
    find("#state_indicator")
  end

  def be_retired
    have_css(".active", text: "Retired")
  end
end
