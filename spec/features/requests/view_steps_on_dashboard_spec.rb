require 'spec_helper'

feature 'User who can view the Requests dashboard', custom_roles: true, js: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given!(:group) { user.groups.first }
  given!(:request) { create(:request, :with_assigned_app, user: user) }
  given!(:app) { request.apps.first }
  given!(:team) { app.teams.first }
  given!(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    team.groups << group
    permissions << 'Requests' << 'View Requests list' << 'View created Requests list'
    sign_in(user)
  end

  scenario 'can see all the Steps for each Request' do
    request.steps << create(:step, name: "This is a step!")
    visit request_dashboard_path
    expect(page).not_to have_content("This is a step!")
    click_on("show steps")
    expect(page).to have_step_named("This is a step!")
  end

  def have_step_named(name)
    have_css(".request_steps td:nth-child(3)", text: name)
  end
end
