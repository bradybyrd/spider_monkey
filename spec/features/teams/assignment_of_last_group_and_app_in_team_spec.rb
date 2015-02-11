require 'spec_helper'

feature 'User on the edit team page', custom_roles: true do
  scenario 'cannot unlink the last group from its app', js: true do
    user = create(:user)
    group = create(:group)
    app = create(:app)
    team_both = create(:team, groups: [group], apps: [app])
    team_group = create(:team, groups: [group], apps: [])
    team_app = create(:team, groups: [], apps: [app])

    sign_in(user)
    visit edit_team_path(team_both)
    expect(checkbox_for_app(app)).to be_disabled
    expect(checkbox_for_group(group)).to be_disabled

    visit edit_team_path(team_app)
    check_group(group)
    visit edit_team_path(team_both)
    expect(checkbox_for_app(app)).to_not be_disabled
    expect(checkbox_for_group(group)).to_not be_disabled
  end

  def checkbox_for_app(app)
    find("#development_team_#{app.id}")
  end

  def checkbox_for_group(group)
    find("#group_ids_#{group.id}")
  end

  def check_group(group)
    checkbox_for_group(group).set(true)
  end
end

