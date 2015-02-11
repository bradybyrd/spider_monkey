require "spec_helper"

feature "Role auditing" do
  scenario "happens on create" do
    given_that_roles_are_audited
    sign_in user_with_role_permissions

    role_name = create_new_role

    expect(page).to have_role_in_list_named(role_name)
    expect(Role).to be_audited("create", role_name)
  end

  scenario "happens on update" do
    given_that_roles_are_audited
    sign_in user_with_role_permissions
    role_name = create_new_role

    new_role_name = update_role(role_name)

    expect(page).to have_role_in_list_named(new_role_name)
    expect(Role).to be_audited("update", [role_name, new_role_name])
  end

  scenario "happens on delete" do
    given_that_roles_are_audited
    sign_in user_with_role_permissions
    role_name = create_new_role

    delete_role(role_name)

    expect(page).to_not have_role_in_list_named(role_name)
    expect(Role).to be_audited("destroy", role_name)
  end

  def given_that_roles_are_audited
    allow(Role).to receive(:publish_message)
  end

  def user_with_role_permissions
    create(:old_user, :root)
  end

  def create_new_role
    visit new_role_path
    fill_out_role_form
  end

  def update_role(role_name)
    click_on(role_name)
    fill_out_role_form
  end

  def fill_out_role_form
    role_name = SecureRandom.uuid
    fill_in "Name", with: role_name
    find("form input[type='submit']").click
    role_name
  end

  def delete_role(role_name)
    row_for(role_name).click_on "Make Inactive"
    row_for(role_name).click_on "Delete"
  end

  def row_for(name)
    find("tr", text: name)
  end

  def have_role_in_list_named(name)
    have_css(".role_name_link", text: name)
  end

  def be_audited(action, name)
    have_received(:publish_message).with(hash_including(
      "action" => action,
      "audited_changes" => hash_including(
        "name" => name
      )
    ))
  end
end
