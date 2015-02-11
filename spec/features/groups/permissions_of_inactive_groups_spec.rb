require 'spec_helper'

feature 'Calculating the permissions of a User in several Groups', custom_roles: true, js: true do
  scenario 'does not use inactive Groups' do
    full_access_group = group_with_permissions("Reports", "Plans")
    no_access_group = group_with_permissions("Plans")
    user = create_user_in_groups(full_access_group, no_access_group)

    signed_in_as(user) do
      expect(page).to show_tabs("Reports", "Plans")
    end

    signed_in_as_admin do
      deactivate_group(full_access_group)
    end

    signed_in_as(user) do
      expect(page).to show_tabs("Plans")
      expect(page).not_to show_tabs("Reports")
    end
  end

  def group_with_permissions(*names)
    role = create(:role)
    permissions = TestPermissionGranter.new(role.permissions)
    permissions << names
    create(:group, roles: [role])
  end

  def create_user_in_groups(*groups)
    create(:user, groups: groups)
  end

  def signed_in_as(user, &block)
    sign_out
    sign_in(user)
    block.call
    sign_out
  end

  def signed_in_as_admin(&block)
    signed_in_as(create(:user, :root), &block)
  end

  def sign_out
    visit logout_path
  end

  def deactivate_group(group)
    visit groups_path
    page.find("tr#group_#{group.id} a.make_inactive_group").click
  end

  RSpec::Matchers.define :show_tabs do |*tab_names|
    match do |page|
      tab_names.all? do |tab_name|
        page.has_css?("#primaryNav ul li", text: tab_name)
      end
    end
  end
end
