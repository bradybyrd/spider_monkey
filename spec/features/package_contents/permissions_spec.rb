require 'spec_helper'

feature 'Package Contents page permissions', custom_roles: true do
  given!(:user) { create(:old_user, :not_admin_with_role_and_group) }
  given!(:package_content) { create(:package_content) }
  given!(:basic_permissions) { [
      'Environment',
      'Access Metadata'
    ] }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  given(:view_package_contents_permission) { 'View Package Contents list' }
  given(:create_package_content_permission) { 'Create Package Contents' }
  given(:edit_package_content_permission) { 'Edit Package Contents' }
  given(:archive_package_content_permission) { 'Archive/Unarchive Package Contents' }
  given(:delete_package_content_permission) { 'Delete Package Contents' }

  background do
    permissions << basic_permissions

    sign_in user
  end

  describe 'PackageContent index page' do
    context 'PackageContent list' do
      scenario 'when does not user has any package_content permissions' do
        visit package_contents_path

        expect(page).not_to have_css('#package_contents')
        expect(page).not_to have_content(package_content.name)
      end

      scenario 'when user has "list package_contents" permission user can view package_contents list' do
        permissions << view_package_contents_permission
        visit package_contents_path

        expect(page).to have_css('#package_contents')
        expect(page).to have_content(package_content.name)
      end
    end

    context '"Create PackageContent" button' do
      background do
        permissions << view_package_contents_permission
      end

      scenario 'when does not user has any package_content permissions except view list' do
        visit package_contents_path
        expect(page).not_to have_css('.create_package_content')

        visit new_package_content_path
        expect(page).not_to have_content('Create PackageContent')
      end

      scenario 'when user has "create package_content" permission user can see "Create package_content" button' do
        permissions << create_package_content_permission
        visit package_contents_path

        expect(page).to have_css('.create_package_content')
        page.find('.create_package_content').click
        expect(page).not_to have_content('Unathorized')
      end
    end

    context '"Edit PackageContent" link' do
      background do
        permissions << view_package_contents_permission
      end

      scenario 'when does not user has any package_content permissions except view list' do
        visit package_contents_path
        expect(page).not_to have_css('.edit_package_content')
        expect(page).not_to have_link(package_content.name)
        expect(page).not_to have_link(package_content.abbreviation)

        visit edit_package_content_path(package_content)
        expect(page).not_to have_content(package_content.name)
      end

      scenario 'when user has "edit package_content" permission user can see "Edit" link' do
        permissions << edit_package_content_permission
        visit package_contents_path

        expect(page).to have_css('.edit_package_content')
        expect(page).to have_link(package_content.name)
        expect(page).to have_link(package_content.abbreviation)
        page.find("#package_content_#{ package_content.id } .edit_package_content").click
        expect(page).to have_content(package_content.name)
      end
    end

    context '"Archive/Unarchive package_content" link' do
      background do
        permissions << view_package_contents_permission
      end

      scenario 'when does not user has any package_content permissions except view list' do
        visit package_contents_path
        expect(page).not_to have_css('.archive_package_content')
        expect(page).not_to have_content('Archived')
      end

      scenario 'when user has "Archive/Unarchive package_content" permission user can see "Archive" link' do
        permissions << archive_package_content_permission
        visit package_contents_path

        expect(page).to have_css('.archive_package_content')
        page.find("#package_content_#{ package_content.id } .archive_package_content").click
        expect(page).not_to have_content('Unauthorized')
      end
    end

    context '"Delete" link' do
      background do
        permissions << view_package_contents_permission
        package_content.archive
      end

      scenario 'when does not user has any package_content permissions except view list' do
        visit package_contents_path
        expect(page).not_to have_css('.delete_package_content')
      end

      scenario 'when user has "Delete package content" permission user can see "Delete" link' do
        permissions << delete_package_content_permission
        visit package_contents_path

        expect(page).to have_css('.delete_package_content')
        page.find("#package_content_#{ package_content.id } .delete_package_content").click
        expect(page).to have_content('Package content was successfully deleted')
      end
    end
  end

end
