require "spec_helper"

feature "Group auditing" do
  scenario "happens on create" do
    given_that_groups_are_audited
    sign_in user_with_group_permissions

    group_name = create_new_group

    expect(page).to have_group_in_list_named(group_name)
    expect(Group).to have_name_audited("create", group_name)
  end

  scenario "happens on update" do
    given_that_groups_are_audited
    sign_in user_with_group_permissions
    group_name = create_new_group

    new_group_name = update_group(group_name)

    expect(page).to have_group_in_list_named(new_group_name)
    expect(Group).to have_name_audited("update", [group_name, new_group_name])
  end

  scenario "happens when a user is added" do
    given_that_groups_are_audited
    user = user_with_group_permissions
    sign_in user
    group_name = create_new_group

    add_user_to_group(user, group_name)

    expect(UserGroup).to be_audited(
      "create",
      "user_id" => user.id, "group_id" => group_named(group_name).id
    )
  end

  scenario "happens when a role is added" do
    given_that_groups_are_audited
    sign_in user_with_group_permissions
    role = create_role
    group_name = create_new_group

    add_role_to_group(role, group_name)

    expect(GroupRole).to be_audited(
      "create",
      "role_id" => role.id, "group_id" => group_named(group_name).id
    )
  end

  scenario "happens when a group is made active and inactive" do
    given_that_groups_are_audited
    sign_in user_with_group_permissions
    group_name = create_new_group

    inactivate_and_activate_group(group_name)

    expect(Group).to be_audited("update", "active" => [true, false])
    expect(Group).to be_audited("update", "active" => [false, true])
  end

  def given_that_groups_are_audited
    allow(UserGroup).to receive(:publish_message)
    allow(GroupRole).to receive(:publish_message)
    allow(Group).to receive(:publish_message)
  end

  def user_with_group_permissions
    create(:old_user, :root)
  end

  def create_role
    create(:role, name: "Something Cool")
  end

  def create_new_group
    visit new_group_path
    fill_out_group_form
  end

  def update_group(group_name)
    click_on(group_name)
    fill_out_group_form
  end

  def add_user_to_group(user, group_name)
    click_on(group_name)
    find("tr", text: user.name_for_index).find("input").set(true)
    click_on("Update")
  end

  def add_role_to_group(role, group_name)
    click_on(group_name)
    find("#group_role_ids", visible: false).set(role.id)
    click_on("Update")
  end

  def inactivate_and_activate_group(group_name)
    within(row_for(group_name)) do
      click_on("Make Inactive")
    end
    within(row_for(group_name)) do
      click_on("Make Active")
    end
  end

  def group_named(name)
    Group.where(name: name).first
  end

  def fill_out_group_form
    group_name = SecureRandom.uuid
    fill_in "Name", with: group_name
    find("form input[type='submit']").click
    group_name
  end

  def row_for(name)
    find("tr", text: name)
  end

  def have_group_in_list_named(name)
    have_css(".group_list_sorter", text: name)
  end

  def have_name_audited(action, name)
    be_audited(action, "name" => name)
  end

  def be_audited(action, options)
    have_received(:publish_message).with(hash_including(
      "action" => action,
      "audited_changes" => hash_including(options)
    ))
  end
end
