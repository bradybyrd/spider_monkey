require 'spec_helper'

feature "RolePermission auditing" do
  scenario "happens when adding and deleting a permission" do
    given_permission_with_id(2)
    role = create_new_role
    given_that_role_permissions_are_audited
    sign_in user_with_role_permissions
    visit roles_path

    permission_id = add_permission_for_role(role.name)
    permission_id = remove_permission_for_role(role.name)

    expect(RolePermission).
      to be_audited(
        "create",
        "role_id" => role.id,
        "permission_id" => permission_id
      )
    expect(RolePermission).
      to be_audited(
        "destroy",
        "role_id" => role.id,
        "permission_id" => permission_id
      )
  end

  def given_permission_with_id(id)
    create(:permission, id: id, name: 'persisting first permissions from role list...')
  end

  def given_that_role_permissions_are_audited
    allow(RolePermission).to receive(:publish_message)
  end

  def user_with_role_permissions
    create(:user, :root)
  end

  def create_new_role
    role_name = SecureRandom.uuid
    create(:role, name: role_name)
  end

  def add_permission_for_role(name)
    set_permission_for_role(name, true)
  end

  def remove_permission_for_role(name)
    set_permission_for_role(name, false)
  end

  def set_permission_for_role(name, value)
    click_on(name)
    last_permission = all("input[type='checkbox']").first
    last_permission.set(value)
    click_on "Update"
    last_permission.value.to_i
  end

  def be_audited(action, changes)
    have_received(:publish_message).with(hash_including(
      "action" => action,
      "audited_changes" => changes
    ))
  end
end
