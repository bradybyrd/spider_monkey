require 'spec_helper'

feature 'User on a edit team page', custom_roles: true do
  scenario 'cannot uncheck all the groups', js: true do
    user = create(:user)
    group_a, group_b = create_list(:group, 2)
    team = create(:team, groups: [group_a, group_b])

    sign_in user
    visit edit_team_path(team)
    uncheck groups(group_a); wait_for_ajax

    expect(group_checkbox(group_b)).not_to be_disabled
  end

  scenario 'can check group which is not assigned to the team yet' do
    user = create(:user, :root)
    group_a, group_b = create_list(:group, 2)
    team = create(:team, groups: [group_a, group_b])

    team.groups = [group_b]

    login_as user
    visit edit_team_path(team)

    expect(group_checkbox(group_a)).not_to be_disabled
  end

  def groups(group)
    "group_ids_#{group.id}"
  end

  def group_checkbox(group)
    find("#group_ids_#{group.id}")
  end
end
