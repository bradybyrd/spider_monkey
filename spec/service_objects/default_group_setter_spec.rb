require 'spec_helper'

describe DefaultGroupSetter do
  it 'makes a group default' do
    group = create(:group)

    DefaultGroupSetter.new(group).make_default_and_assign_to_default_team

    expect(group).to be_default
  end

  it 'automatically assigns default group to a default team' do
    team = create(:default_team)
    group = create(:group)

    DefaultGroupSetter.new(group).make_default_and_assign_to_default_team

    expect(team.reload.groups).to include group
  end

  it "assigns group's users to the team's apps" do
    user = create(:user)
    app = create(:app)
    team = create(:default_team)
    team.apps = [app]
    group = create(:group)
    group.users = [user]

    DefaultGroupSetter.new(group).make_default_and_assign_to_default_team

    expect(app.reload.users).to include user
  end
end