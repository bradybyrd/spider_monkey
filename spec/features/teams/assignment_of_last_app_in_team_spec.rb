require 'spec_helper'

feature 'User on an edit team page', custom_roles: true do
  scenario 'can uncheck app that belongs to more than one team', js: true do
    user = create(:user)
    app = create(:app, name: 'Sick App')
    teams = create_list(:team, 2, apps: [app])

    sign_in user
    visit edit_team_path(teams.first)
    uncheck application_checkbox_selector(app)
    wait_for_ajax

    expect(application_checkbox(app)).not_to be_checked
  end

  scenario 'can check application which is not assigned to current team yet' do
    user = create(:user, :root)
    app = create(:app, teams: [build(:team)])
    team = create(:team)

    login_as user
    visit edit_team_path(team)

    expect(application_checkbox(app)).not_to be_disabled
  end

  def application_checkbox(app)
    find("##{application_checkbox_selector(app)}")
  end

  def application_checkbox_selector(app)
    "development_team_#{app.id}"
  end
end