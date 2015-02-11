################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe Role do
  context "check associations" do
    it { should have_many(:role_permissions) }
    it { should have_many(:permissions).through(:role_permissions) }
    it { should have_many(:group_roles) }
    it { should have_many(:groups).through(:group_roles) }
    it { should have_many(:users).through(:groups) }
    it { should have_many(:teams).through(:groups) }
    it { should have_many(:team_group_app_env_roles) }
  end

  describe '#group_names' do
    it 'returns names of assigned groups' do
      group1 = create(:group, name: 'group')
      group2 = create(:group, name: 'root', root: true)
      role = create(:role, group_ids: [group1.id, group2.id])

      expect(role.group_names).to eq('group, root')
    end
  end

  describe '#team_names' do
    it 'returns names of teams names' do
      team1 = create(:team, name: 'first')
      team2 = create(:team, name: 'second')
      group = create(:group, team_ids: [team1.id, team2.id])
      role = create(:role, group_ids: [group.id])

      expect(role.team_names).to eq('first, second')
    end
  end

  it "is #deactivatable? if it has no groups" do
    role = create(:role, group_ids: [])

    expect(role).to be_deactivatable
  end

  it "is not deactivatable if it has groups" do
    group = create(:group)
    role = create(:role, group_ids: [group.id])

    expect(role).to_not be_deactivatable
  end

  it "will only allow deactivation if the role has no groups" do
    group = create(:group)
    role = create(:role, group_ids: [], active: true)

    role.deactivate!

    expect(role).to_not be_active
  end

  it "will not allow deactivation if the role has groups" do
    group = create(:group)
    role = create(:role, group_ids: [group.id], active: true)

    role.deactivate!

    expect(role).to be_active
  end

end
