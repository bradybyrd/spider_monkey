################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe Group do
  context 'with user' do
    before do
      User.current_user = User.find_by_login('admin')
      @group = create(:group)
    end

    describe 'validations' do
      it { @group.should validate_presence_of(:name) }
      it { @group.should validate_uniqueness_of(:name) }

      it 'does not allow the name to begin with a negative number' do
        @group.name = '-1 blah'
        expect(@group).not_to be_valid
        expect(@group.errors[:name].size).to eq(1)
      end

      it 'does not allow update of inactive group', custom_roles: true do
        group = build(:group, active: false)
        group.update_attributes(name: 'test')
        expect(group.errors_on(:base)).to include I18n.t('group.edit_error')
      end

      it 'allow to update up-to-date record' do
        @group.name = 'abc'
        expect(@group).to be_valid
        expect(@group.errors).to be_empty
      end

      it 'do not allow to update outdated record' do
        @group.name = 'xyz'
        @group.updated_at -= 1.second
        expect(@group).not_to be_valid
        expect(@group.errors[:base]).to include I18n.t('activerecord.errors.object.stolen')
      end
    end

    describe 'associations' do
      it 'should have many' do
        @group.should have_many(:user_groups)
        @group.should have_many(:resources)
        @group.should have_many(:placeholder_resources)
        @group.should have_many(:team_groups)
        @group.should have_many(:teams)
        @group.should have_many(:steps)
        @group.should have_many(:group_roles)
        @group.should have_many(:roles).through(:group_roles)
        @group.should have_many(:apps).through(:teams)
      end
    end
  end

  describe '#root_group?' do
    it 'returns true if group is root' do
      group = create(:group, name: 'root_group', root: true)
      expect(group.root_group?).to be(true)
    end

    it 'returns false if group is not root' do
      group = create(:group, name: 'root_group', root: false)
      expect(group.root_group?).to be(false)
    end
  end

  describe '#filtered' do
    before(:all) do
      Group.delete_all
      @group1 = create(:group)
      @group2 = create(:group, name: 'Inactive Group', active: false)
      @group3 = create(:group, name: 'Default Group')
      @active = [@group1, @group3]
      @inactive = [@group2]
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'Default Group')
        result.should match_array([@group3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => 'Inactive Group')
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:inactive => true, :name => 'Inactive Group')
        result.should match_array([@group2])
      end
    end
  end

  describe '#deactivate!', custom_roles: true do

    it 'makes group inactive if user inside of it has relations with other groups' do
      groups = build_list :group, 2
      create :user, groups: groups

      expect(groups.first.deactivate!).to eq true
    end

    it 'does not make group inactive if user is related only to current group' do
      group, other_group = build_list(:group, 2)
      create :user, groups: [group, other_group]
      create :user, groups: [group]

      expect(group.deactivate!).to eq false
    end
  end

  context 'with name "Root"', custom_roles: true do
    it 'cannot be made inactive' do
      user = stub_model User, name: 'G'
      group = build :group, name: Group::ROOT_NAME, active: true, resources: [user]

      expect{group.deactivate!}.not_to change{group.active?}
    end

    it 'cannot be made non root' do
      group = stub_model Group, name: Group::ROOT_NAME, root: true

      group.root = false

      expect(group).not_to be_valid
      expect(group.errors.full_messages).to include I18n.t(:'group.errors.cannot_be_made_non_root', name: Group::ROOT_NAME)
    end

    it 'cannot be deleted' do
      group = mock_model Group, name: Group::ROOT_NAME

      expect{group.destroy}.not_to change{Group.count}
    end

    it 'should have at least one user assigned' do
      user = stub_model User, login: 'G'
      group = stub_model Group, name: Group::ROOT_NAME, resources: [user]

      group.resources = []

      expect(group).not_to be_valid
      expect(group.errors.full_messages).to include I18n.t(:'group.errors.should_contain_at_lease_one_user', name: Group::ROOT_NAME)
    end

    it 'cannot have name changed' do
      group = stub_model Group, name_was: Group::ROOT_NAME

      group.name = 'New name'

      expect(group).not_to be_valid
      expect(group.errors.full_messages).to include I18n.t(:'group.errors.name_cannot_be_changed', name: Group::ROOT_NAME)
    end
  end

  describe '.default_group' do
    it 'returns default group' do
      group = create :group
      default_group = create :default_group

      expect(Group.default_group).to eq default_group
    end
  end

  describe '.active' do
    it 'returns in name order' do
      # remove the groups created from the before
      Group.delete_all

      group_last = create(:group, name:'d')
      group_second = create(:group, name:'b')
      group_first = create(:group, name:'a')
      group_third = create(:group, name:'c')

      groups = Group.active

      expect(groups.count).to eq 4
      expect(groups[0].name).to eq group_first.name
      expect(groups[1].name).to eq group_second.name
      expect(groups[2].name).to eq group_third.name
      expect(groups[3].name).to eq group_last.name

    end
  end

end
