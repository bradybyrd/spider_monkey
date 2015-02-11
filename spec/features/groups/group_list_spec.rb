require 'spec_helper'

feature 'User on a groups list page', custom_roles: true do
  context 'having group with name "Root"' do
    it 'does not see the make inactive button' do
      group = create :group, :with_users, user_count: 1, name: Group::ROOT_NAME, root: true
      user = group.resources.first

      sign_in user
      visit groups_path

      expect(group_actions_section(group)).not_to have_inactive_button
    end
  end

  def have_inactive_button
    have_content I18n.t(:make_inactive)
  end

  def group_actions_section(group)
    edit_link(group).parent
  end

  def edit_link(group)
    find(".action_links > span a[href='#{edit_group_path(group.id)}']")
  end
end
