require "spec_helper"

describe GroupDeactivationPolicy do
  describe "#can_be_deactivated?" do
    context "with regular group" do
      it "is true when a group's resources have more than 1 active group" do
        group, other_group, inactive_group = create_list(:group, 3)
        create :user, groups: [group, other_group, inactive_group]
        inactive_group.update_attribute :active, false
        group_deactivation_policy = GroupDeactivationPolicy.new(group)

        expect(group_deactivation_policy.can_be_deactivated?).to eq true
      end

      it "is false when a group's resources have less than 2 groups at all" do
        group = create :group
        group_deactivation_policy = GroupDeactivationPolicy.new(group)
        create :user, groups: [group]

        expect(group_deactivation_policy.can_be_deactivated?).to eq false
      end

      it "is false when a group's resources have less than 2 active groups" do
        active_group, inactive_group = create_pair :group
        create :user, groups: [active_group, inactive_group]
        inactive_group.update_attribute :active, false
        group_deactivation_policy = GroupDeactivationPolicy.new(active_group)

        expect(group_deactivation_policy.can_be_deactivated?).to eq false
      end
    end

    context "with group with name 'Root'" do
      it "returns false when group's resources have more than 1 group" do
        group = create :group, :with_users, user_count: 1, name: Group::ROOT_NAME, root: true
        other_group = create :group
        user = group.resources.first
        user.groups = [other_group, group]
        group_deactivation_policy = GroupDeactivationPolicy.new(group)

        expect(group_deactivation_policy.can_be_deactivated?).to eq false
      end
    end

  end
end
