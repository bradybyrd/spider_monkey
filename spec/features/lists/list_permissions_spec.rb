require 'spec_helper'

feature 'User on a list page', custom_roles: true, js: true do
  given!(:user)             { create(:user, :non_root, :with_role_and_group, login: 'Enigma') }
  given!(:list)             { create(:list, name: 'Black Hole') }
  given!(:permissions)      { user.groups.first.roles.first.permissions }
  given!(:permissions_list) { PermissionsList.new }
  given(:permission_to) do
    {
        list: {
            list:              create(:permission, permissions_list.permission('View Lists list')),
            create:            create(:permission, permissions_list.permission('Create Lists')),
            edit:              create(:permission, permissions_list.permission('Edit Lists')),
            archive_unarchive: create(:permission, permissions_list.permission('Archive/Unarchive Lists')),
            delete:            create(:permission, permissions_list.permission('Delete Lists'))
        }
    }
  end

  background do
    sign_in(user)
  end

  context 'with the appropriate permissions' do

    scenario 'sees the list of the list items' do
      permissions << permission_to[:list][:list]

      visit lists_path

      expect(page).to have_css('div#lists > table')
      expect(page).to have_content(list.name)
    end

    scenario 'creates a new list' do
      list_name  = 'To list ot not to list'
      permissions       << permission_to[:list][:list]
      permissions       << permission_to[:list][:create]

      visit lists_path

      click_on add_new_list
      wait_for_ajax
      fill_in :list_name, with: list_name
      click_on I18n.t(:create)
      wait_for_ajax

      expect(page).to have_content list_created_message
      expect(page).to have_content list_name
    end

    scenario 'edits the list' do
      list_new_name = 'Roses are red'
      permissions << permission_to[:list][:list]
      permissions << permission_to[:list][:edit]

      visit lists_path

      click_on I18n.t(:edit)
      fill_in :list_name, with: list_new_name
      click_on I18n.t(:update)
      wait_for_ajax

      expect(page).to have_content list_updated_message
      expect(page).to have_content list_new_name
    end

    scenario 'archives and unarchives a list' do
      permissions << permission_to[:list][:list]
      permissions << permission_to[:list][:archive_unarchive]

      visit lists_path

      expect(page).to have_link(I18n.t(:archive))

      click_on I18n.t(:archive)
      wait_for_ajax

      expect(page).to have_link(I18n.t(:unarchive))
      expect(list.reload).to be_archived

      click_on I18n.t(:unarchive)
      wait_for_ajax

      expect(page).to have_link(I18n.t(:archive))
      expect(current_path).to eq lists_path
      expect(list.reload).not_to be_archived
    end

    scenario 'deletes an archived list' do
      list.archive
      permissions << permission_to[:list][:list]
      permissions << permission_to[:list][:delete]

      visit lists_path

      expect(page).to have_link(I18n.t(:delete))

      click_on I18n.t(:delete)

      expect(page).to have_content list_deleted_message
      expect(page).not_to have_content list.name
      expect(current_path).to eq lists_path
    end

  end
end


def list_created_message
  I18n.t(:'activerecord.notices.created', model: I18n.t('activerecord.models.list'))
end

def list_updated_message
  I18n.t(:'activerecord.notices.updated', model: I18n.t('activerecord.models.list'))
end

def list_deleted_message
  I18n.t(:'activerecord.notices.deleted', model: I18n.t(:'activerecord.models.list'))
end

def add_new_list
  I18n.t(:'list.buttons.add_new')
end
