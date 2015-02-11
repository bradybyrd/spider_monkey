require 'spec_helper'

feature 'Environment types page permissions', custom_roles: true do
  given!(:user) { create(:old_user, :not_admin_with_role_and_group) }
  given!(:environment_type) { create(:environment_type) }
  given!(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    permissions << 'View Applications list' << 'Environment' << 'Access Metadata'

    sign_in user
  end

  describe 'environment types index page' do
    context 'environment types list' do
      scenario 'when does not user has any environment_type permissions' do
        visit environment_types_path

        expect(page).not_to have_environment_types_list
        expect(page).to have_no_access_message
      end

      scenario 'when user has "list environment_types" permission user can view environment_types list' do
        permissions << 'View Environment Types list'
        visit environment_types_path

        expect(page).not_to have_no_access_message
        expect(page).to have_environment_types_list
        expect(page).to have_content(environment_type.name)
      end
    end

    context '"Create New Environment Type" button' do
      background do
        permissions << 'View Environment Types list'
      end

      scenario 'when does not user has any environment_type permissions except view list' do
        visit environment_types_path
        expect(page).not_to have_css('.create_environment_type')

        visit new_environment_type_path
        expect(page).to have_no_access_message
      end

      scenario 'when user has "create environment_type" permission user can see "Create environment_type" button' do
        permissions << 'Create Environment Types'
        visit environment_types_path

        expect(page).to have_css('.create_environment_type')
        page.find('.create_environment_type').click
        expect(page).to have_content('Create New Environment Type')
      end
    end

    context '"Edit EnvironmentType" link' do
      background do
        permissions << 'View Environment Types list'
      end

      scenario 'when does not user has any environment_type permissions except view list' do
        visit environment_types_path
        expect(page).not_to have_css('.edit_environment_type')
        expect(page).not_to have_link(environment_type.name)

        visit edit_environment_type_path(environment_type)
        expect(page).to have_no_access_message
      end

      scenario 'when user has "edit environment_type" permission user can see "Edit" link' do
        permissions << 'Edit Environment Types'
        visit environment_types_path

        expect(page).to have_link(environment_type.name)
        expect(page).to have_css('.edit_environment_type')
        page.find("#environment_type_#{ environment_type.id } .edit_environment_type").click
        expect(page).to have_content(environment_type.name)
      end
    end

    context '"Archive/Unarchive Environment Types" link' do
      background do
        permissions << 'View Environment Types list'
      end

      scenario 'when does not user has any environment_type permissions except view list' do
        visit environment_types_path
        expect(page).not_to have_css('.archive_environment_type')
        expect(page).not_to have_content('Archived')
      end

      scenario 'when user has "Archive/Unarchive Environment Types" permission user can see "Make Default" link' do
        permissions << 'Archive/Unarchive Environment Types'
        visit environment_types_path

        expect(page).to have_css('.archive_environment_type')
        page.find("#environment_type_#{ environment_type.id } .archive_environment_type").click
        expect(page).not_to have_content('Unauthorized')
      end
    end

    context '"Delete" link' do
      background do
        permissions << 'View Environment Types list'
        environment_type.archive
      end

      scenario 'when does not user has any environment_type permissions except view list' do
        visit environment_types_path
        expect(page).not_to have_css('.delete_environment_type')
      end

      scenario 'when user has "Delete Environment Types" permission user can see "Delete" link' do
        permissions << 'Delete Environment Types'
        visit environment_types_path

        expect(page).to have_css('.delete_environment_type')
        page.find("#environment_type_#{ environment_type.id } .delete_environment_type").click
        expect(page).to have_content('Environment type was successfully deleted')
      end
    end
  end

  def have_environment_types_list
    have_css('#environment_types')
  end

  def have_no_access_message
    have_content(I18n.t(:'activerecord.errors.no_access_to_view_page'))
  end

end
