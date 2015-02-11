require 'spec_helper'

feature 'User on an edit group page', custom_roles: true do
  context 'having group with name "Root"' do
    it 'cannot unassign all the users' do
      group = create :group, :with_users, user_count: 1, name: Group::ROOT_NAME, root: true
      user = group.resources.first
      sign_in(user)
      visit edit_group_path(group)

      uncheck_user_checkbox(user)
      click_on update_button

      expect(validation_messages).to include_users_limitation_message
    end
  end

  context 'having a root group' do
    it 'can unassign all the users' do
      create :default_group
      group = create :group, :with_users, user_count: 1, root: true
      user = group.resources.first
      sign_in(user)
      visit edit_group_path(group)

      uncheck_user_checkbox(user)
      click_on update_button

      expect(page).not_to include_the_group(group)
      expect(group.users).to be_empty
    end
  end

  def include_the_group(group)
    have_content group.name
  end

  def update_button
    I18n.t(:update)
  end

  def uncheck_user_checkbox(user)
    uncheck "group_resource_ids_#{user.id}"
  end

  def validation_messages
    find '#errorExplanation'
  end

  def include_users_limitation_message
    have_content I18n.t(:'group.errors.should_contain_at_lease_one_user', name: Group::ROOT_NAME)
  end
end
