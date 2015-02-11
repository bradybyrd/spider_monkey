require 'spec_helper'

describe RequestStepsEmailList do
  it 'returns user email if user is the step owner' do
    user = create(:user, email: 'we_will@rock.you')
    step = create(:step, owner: user)

    expect(RequestStepsEmailList.new.get([step])).to eq(['we_will@rock.you'])
  end

  it "returns group's email and group's user's emails if group is a step owner" do
    group = create(:group, email: 'I_wish@I_could.fly')
    user = create(:user, email: 'said@pin.guin')
    step = create(:step, owner: group)
    group.users = [user]

    expect(RequestStepsEmailList.new.get([step])).to match_array(%w(I_wish@I_could.fly said@pin.guin))
  end

  it "returns a list of steps' owners' emails without users' and groups' emails unrelated to steps" do
    some_group = create(:group, email: 'FATAL@a.com')
    some_user = create(:user, email: 'ERROR@a.com')
    step_group = create(:group, email: 'group@ab.com')
    step_user = create(:user, email: 'user@a.com')
    step_group_user = create(:user, email: 'user@b.com')
    step_with_user_owner = create(:step, owner: step_user)
    step_with_group_owner = create(:step, owner: step_group)
    some_group.users = [some_user]
    step_group.users = [step_group_user]

    actual_emails = RequestStepsEmailList.new.get([step_with_user_owner, step_with_group_owner])

    expect(actual_emails).to match_array([step_user.email, step_group.email, step_group_user.email])
  end
end