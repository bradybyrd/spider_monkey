require 'spec_helper'

feature 'Releases page permissions', custom_roles: true do
  given!(:user) { create(:old_user, :not_admin_with_role_and_group) }
  given!(:release) { create(:release) }
  given!(:basic_permissions) { [
      create(:permission, name: 'View applications', action: :view, subject: :my_applications ),
      create(:permission, name: 'Environment tab view', action: :view, subject: :environment_tab),
      create(:permission, name: 'Metadata', action: :view, subject: :metadata)
    ] }

  given(:permissions) { user.groups.first.roles.first.permissions }

  given(:view_releases_permission) { create(:permission, name: 'View releases list', action: :list, subject: 'Release') }
  given(:create_release_permission) { create(:permission, name: 'Create release', action: :create, subject: 'Release') }
  given(:edit_release_permission) { create(:permission, name: 'Edit release', action: :edit, subject: 'Release') }
  given(:archive_release_permission) { create(:permission, name: 'Archive/Unarchive release', action: :archive_unarchive, subject: 'Release') }
  given(:delete_release_permission) { create(:permission, name: 'Delete release', action: :delete, subject: 'Release') }

  background do
    permissions << basic_permissions

    sign_in user
  end

  describe 'releases index page' do
    context 'releases list' do
      scenario 'when does not user has any release permissions' do
        visit releases_path

        expect(page).not_to have_css('#releases')
        expect(page).not_to have_content(release.name)
      end

      scenario 'when user has "list releases" permission user can view releases list' do
        permissions << view_releases_permission
        visit releases_path

        expect(page).to have_css('#releases')
        expect(page).to have_content(release.name)
      end
    end

    context '"Create Release" button' do
      background do
        permissions << view_releases_permission
      end

      scenario 'when does not user has any release permissions except view list' do
        visit releases_path
        expect(page).not_to have_css('.create_release')

        visit new_release_path
        expect(page).not_to have_content('Create Release')
      end

      scenario 'when user has "create release" permission user can see "Create release" button' do
        permissions << create_release_permission
        visit releases_path

        expect(page).to have_css('.create_release')
        page.find('.create_release').click
        expect(page).not_to have_content('Unathorized')
      end
    end

    context '"Edit Release" link' do
      background do
        permissions << view_releases_permission
      end

      scenario 'when does not user has any release permissions except view list' do
        visit releases_path
        expect(page).not_to have_css('.edit_release')
        expect(page).not_to have_link(release.name)

        visit edit_release_path(release)
        expect(page).not_to have_content(release.name)
      end

      scenario 'when user has "edit release" permission user can see "Edit" link' do
        permissions << edit_release_permission
        visit releases_path

        expect(page).to have_css('.edit_release')
        expect(page).to have_link(release.name)
        page.find("#release_#{ release.id } .edit_release").click
        expect(page).to have_content(release.name)
      end
    end

    context '"Archive/Unarchive Releases" link' do
      background do
        permissions << view_releases_permission
      end

      scenario 'when does not user has any release permissions except view list' do
        visit releases_path
        expect(page).not_to have_css('.archive_release')
        expect(page).not_to have_content('Archived')
      end

      scenario 'when user has "Archive/Unarchive Release" permission user can see "Archive" link' do
        permissions << archive_release_permission
        visit releases_path

        expect(page).to have_css('.archive_release')
        page.find("#release_#{ release.id } .archive_release").click
        expect(page).not_to have_content('Unauthorized')
      end
    end

    context '"Delete" link' do
      background do
        permissions << view_releases_permission
        release.archive
      end

      scenario 'when does not user has any release permissions except view list' do
        visit releases_path
        expect(page).not_to have_css('.delete_release')
      end

      scenario 'when user has "Delete Release" permission user can see "Delete" link' do
        permissions << delete_release_permission
        visit releases_path

        expect(page).to have_css('.delete_release')
        page.find("#release_#{ release.id } .delete_release").click
        expect(page).to have_content('Release was successfully deleted')
      end
    end
  end

end
