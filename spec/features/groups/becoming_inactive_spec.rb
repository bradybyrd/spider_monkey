require 'spec_helper'

feature "Groups cannot become inactive" do
  scenario "when they are the only active Group for a User" do
    user = create_user_in_two_groups
    first_group = user.groups.first
    second_group = user.groups.second
    sign_in_as_admin

    visit groups_path

    expect(page).to be_able_to_make_inactive(first_group)
    expect(page).to be_able_to_make_inactive(second_group)

    make_inactive(first_group)

    expect(page).to_not be_able_to_make_inactive(second_group)
  end

  def create_user_in_two_groups
    user = create(:user, :non_root)
    user.groups = create_pair(:group)
    user
  end

  def sign_in_as_admin
    sign_in create(:user, :root)
  end

  def be_able_to_make_inactive(group)
    have_css(inactive_link_selector(group), text: "Make Inactive")
  end

  def make_inactive(group)
    find(inactive_link_selector(group), text: "Make Inactive").click
  end

  def inactive_link_selector(group)
    "#group_#{group.id} a"
  end
end
