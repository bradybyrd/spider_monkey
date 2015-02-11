require 'spec_helper'

feature 'Server Levels permissions', js: true, custom_roles: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given!(:property) { create(:property) }
  given!(:server_level) { create(:server_level, properties: [property]) }
  given!(:server_aspect) { create(:server_aspect, server_level: server_level, properties_with_values: [property]) }

  given(:permissions) { user.groups.first.roles.first.permissions }

  given(:access_servers_permission) { create(:permission, name: 'Access Servers', action: 'view', subject: 'server_tabs') }
  given(:environment_tab_permission) { create(:permission, name: 'Environment Tab', action: 'view', subject: 'environment_tab') }

  given(:list_permission) { create(:permission, name: 'List', action: 'list', subject: 'ServerLevel') }
  given(:inspect_permission) { create(:permission, name: 'Inspect', action: 'inspect', subject: 'ServerLevel') }

  given(:managing_permissions) do
    [
      create(:permission, name: 'Create', action: 'create', subject: 'ServerLevel'),
      create(:permission, name: 'Edit', action: 'edit', subject: 'ServerLevel'),
      create(:permission, name: 'Add Instance', action: 'add', subject: 'ServerAspect'),
      create(:permission, name: 'Edit Instance', action: 'edit', subject: 'ServerAspect'),
      create(:permission, name: 'Delete Instance', action: 'delete', subject: 'ServerAspect'),
      create(:permission, name: 'Edit Instance Property', action: 'edit_property', subject: 'ServerAspect'),
      create(:permission, name: 'Deassign Property', action: 'delete_property', subject: 'ServerLevel'),
      create(:permission, name: 'Create Property', action: 'create', subject: 'Property'),
      create(:permission, name: 'Edit Property', action: 'edit', subject: 'Property')
    ]
  end

  background do
    User.stub(:current_user).and_return(user)
    permissions << [environment_tab_permission, access_servers_permission]
    sign_in user
  end

  describe 'tabs' do
    context 'w/o list permission' do
      scenario 'tab not available' do
        visit servers_path

        within '.server_tabs' do
          expect(page).to have_no_link 'Server Levels'
        end
      end
    end

    context 'with list permission' do
      before { permissions << list_permission }

      scenario 'tab available' do
        visit servers_path

        within '.server_tabs' do
          expect(page).to have_link 'Server Levels'
          expect(page).to have_no_link server_level.name
          expect(page).to have_content server_level.name
        end
      end

      context 'with inspect permission' do
        scenario 'can view item' do
          permissions << inspect_permission
          visit servers_path

          within '.server_tabs' do
            expect(page).to have_link server_level.name
          end
        end
      end
    end
  end

  describe 'viewing server level' do
    before { permissions << [list_permission, inspect_permission] }

    scenario 'read only page' do
      visit server_level_path(server_level)

      within '.Right #sidebar' do
        expect(page).to have_no_link 'Create_server_level'
      end

      within '#server_container' do
        expect(page).to have_no_content 'Edit'
        expect(page).to have_no_content 'Add New Instance'
        expect(page).to have_no_content 'Add new Property'

        within '#server_levels' do
          expect(page).to have_no_link server_aspect.name
          expect(page).to have_content server_aspect.name

          expect(page).to have_no_link property.name
          expect(page).to have_content property.name

          expect(page).to have_no_link 'delete'
        end

        within '#server_level_properties' do
          expect(page).to have_no_link property.name
          expect(page).to have_content property.name

          expect(page).to have_no_button 'delete'
        end
      end
    end

    scenario 'all permissions' do
      permissions << managing_permissions
      visit server_level_path(server_level)

      within '.Right #sidebar' do
        expect(page).to have_link 'Create_server_level'
      end

      within '#server_container' do
        expect(page).to have_link 'Edit'
        expect(page).to have_link 'Add New Instance'
        expect(page).to have_link 'Add new Property'

        within '#server_levels' do
          expect(page).to have_link server_aspect.name
          expect(page).to have_link property.name
          expect(page).to have_link 'delete'
        end

        within '#server_level_properties' do
          expect(page).to have_link property.name
          expect(page).to have_link 'delete'
        end
      end
    end
  end

end
