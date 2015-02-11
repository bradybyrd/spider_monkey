require 'spec_helper'

feature 'User on a version_tag page', custom_roles: true, js: true do
  given!(:user)             { create(:user, :non_root, :with_role_and_group, login: 'Storm Spirit') }
  given!(:version_tag)      { create(:version_tag, :proper, name: 'Earth Shaker') }
  given!(:permissions)      { user.groups.first.roles.first.permissions }
  given!(:permissions_list) { PermissionsList.new }
  given!(:permission_to) do
    {
        version_tag: {
            list:              create(:permission, permissions_list.permission('View Version Tags list')),
            create:            create(:permission, permissions_list.permission('Create Version Tags/Bulk Create Version Tags')),
            edit:              create(:permission, permissions_list.permission('Edit Version Tags')),
            archive_unarchive: create(:permission, permissions_list.permission('Archive/Unarchive Version Tags')),
            delete:            create(:permission, permissions_list.permission('Delete Version Tags'))
        }
    }
  end

  background { sign_in(user) }

  context 'with the appropriate permissions' do

    scenario 'sees the list of the version_tags' do
      VersionTag.any_instance.stub(:environment_name).and_return 'some name'
      InstalledComponent.any_instance.stub(:name).and_return 'some name'

      visit version_tags_path

      expect(page).not_to have_content(version_tag.name)
      permissions << permission_to[:version_tag][:list]

      visit version_tags_path

      expect(page).to have_css('div#search_result table')
      expect(page).to have_content(version_tag.name)
    end

    scenario 'creates a new version_tag' do
      version_tag_name  = 'Hamlet'
      application       = create(:app, :with_installed_component)
      permissions       << permission_to[:version_tag][:list]

      visit version_tags_path

      expect(page).not_to have_button I18n.t(:'version_tag.buttons.add_new')
      permissions       << permission_to[:version_tag][:create]

      visit version_tags_path

      click_on I18n.t(:'version_tag.buttons.add_new')
      fill_in :version_tag_name, with: version_tag_name
      select application.name, from: :app_id
      wait_for_ajax

      click_on I18n.t(:create)
      wait_for_ajax

      expect(page).to have_content version_tag_created_message
      expect(page).to have_content version_tag_name
    end

    scenario 'edits the version_tag' do
      version_tag_new_name  = 'Violets are blue'
      permissions           << permission_to[:version_tag][:list]

      visit version_tags_path

      expect(page).not_to have_link I18n.t(:edit)
      expect(page).not_to have_link version_tag.name
      permissions           << permission_to[:version_tag][:edit]

      visit version_tags_path

      click_on I18n.t(:edit)
      fill_in :version_tag_name, with: version_tag_new_name
      click_on I18n.t(:update)
      wait_for_ajax

      expect(page).to have_content version_tag_updated_message
      expect(page).to have_link version_tag_new_name
    end

    scenario 'archives and unarchives a version_tag' do
      permissions << permission_to[:version_tag][:list]

      visit version_tags_path

      expect(page).not_to have_link I18n.t(:archive)
      permissions << permission_to[:version_tag][:archive_unarchive]

      visit version_tags_path

      expect(page).to have_link I18n.t(:archive)
      click_on I18n.t(:archive)
      wait_for_ajax

      expect(page).to have_link I18n.t(:unarchive)
      expect(version_tag.reload).to be_archived
      click_on I18n.t(:unarchive)
      wait_for_ajax

      expect(page).to have_link I18n.t(:archive)
      expect(current_path).to eq version_tags_path
      expect(version_tag.reload).not_to be_archived
    end

    scenario 'deletes an archived version_tag' do
      version_tag.archive
      permissions << permission_to[:version_tag][:list]

      visit version_tags_path

      expect(page).not_to have_link(I18n.t(:delete))
      permissions << permission_to[:version_tag][:delete]

      visit version_tags_path

      expect(page).to have_link(I18n.t(:delete))

      click_on I18n.t(:delete)

      expect(page).to have_content version_tag_deleted_message
      expect(page).not_to have_content version_tag.name
      expect(current_path).to eq version_tags_path
    end

  end
end


def version_tag_created_message
  I18n.t(:'activerecord.notices.created', model: I18n.t(:'activerecord.models.version_tag'))
end

def version_tag_updated_message
  I18n.t(:'activerecord.notices.updated', model: I18n.t(:'activerecord.models.version_tag'))
end

def version_tag_deleted_message
  I18n.t(:'activerecord.notices.deleted', model: I18n.t(:'activerecord.models.version_tag'))
end
