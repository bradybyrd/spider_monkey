require 'spec_helper'

feature 'Tickets permissions', js: true, custom_roles: true do
  given!(:ticket) { create(:ticket) }
  given!(:user) { create(:user, :non_root, :with_role_and_group) }

  given(:permissions) { user.groups.first.roles.first.permissions }

  given(:access_metadata_permission) { create(:permission, name: 'Metadata', action: 'access', subject: 'metadata') }
  given(:list_permission) { create(:permission, name: 'List', action: 'list', subject: 'Ticket') }
  given(:create_permission) { create(:permission, name: 'Create', action: 'create', subject: 'Ticket') }
  given(:edit_permission) { create(:permission, name: 'Edit', action: 'edit', subject: 'Ticket') }
  given(:delete_permission) { create(:permission, name: 'Delete', action: 'delete', subject: 'Ticket') }

  background do
    permissions << access_metadata_permission
    sign_in user
  end

  describe 'metadata' do
    scenario 'can not access tickets' do
      visit manage_metadata_path

      within '#LinkList' do
        expect(page).to have_no_content 'Manage Tickets'
      end
    end

    scenario 'can access tickets' do
      permissions << list_permission
      visit manage_metadata_path

      within '#LinkList' do
        expect(page).to have_link 'Manage Tickets'
      end
    end
  end

  describe 'list' do
    context 'with list permission' do
      before { permissions << list_permission }

      scenario 'can view list' do
        visit tickets_path

        expect(page).to have_no_button 'Create Ticket'

        within '.ticketList' do
          expect(page).to have_no_link ticket.name
          expect(page).to have_content ticket.name
          expect(page).to have_no_link 'Bin_empty'
        end
      end

      context 'with delete, create and edit permissions' do
        scenario 'able to edit, create and delete' do
          permissions << [create_permission, edit_permission, delete_permission]
          visit tickets_path

          expect(page).to have_button 'Create Ticket'

          within '.ticketList' do
            expect(page).to have_link ticket.name
            expect(page).to have_link 'Bin_empty'
          end
        end
      end
    end
  end
end
