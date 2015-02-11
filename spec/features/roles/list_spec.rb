require 'spec_helper'

feature 'Roles list', custom_roles: true, js: true do
  given!(:admin) { create(:user, :root) }
  given!(:team) { create(:team) }
  given!(:group) { create(:group, teams: [team]) }
  given!(:basic_permissions) { [
      create(:permission, name: 'View applications', action: :view, subject: :my_applications ),
      create(:permission, name: 'View dashboard tab', action: :view, subject: :dashboard_tab ),
      create(:permission, name: 'System tab view', action: :view, subject: :system_tab),
      create(:permission, name: 'View roles list', action: :list, subject: 'Role')
    ] }

  given(:permissions) { user.groups.first.roles.first.permissions }

  context 'when no roles and user is admin' do
    background do
      Role.delete_all

      sign_in admin
    end

    describe 'List' do
      scenario 'shows message and hides table' do
        visit roles_path

        expect(page).to have_content I18n.t('role.none')
        expect(page).to have_no_css '.roles_table'
      end
    end
  end

  context 'when roles are available' do
    given!(:user) { create(:user, :with_role_and_group) }
    given!(:active_role) { create(:role, groups: [group]) }
    given!(:active_role_2) { create(:role) }
    given!(:inactive_role) { create(:role, active: false) }
    given!(:inactive_role_2) { create(:role, active: false) }
    given(:active_roles) { Role.active }

    background do
      permissions << basic_permissions
      sign_in user

      visit roles_path
      click_link 'clear'
      wait_for_ajax
    end

    describe 'List' do
      scenario 'table displays roles' do
        pending 'failing randomly. Fix in custom roles'

        expect(page).to have_content('Active')
        expect(page).to have_content('Inactive')
        expect(page).to have_content('4 Items', count: 2)

        within '.roles_table.active' do
          expect(page).to have_content active_role.name
          expect(page).to have_content group.name
        end

        within '.roles_table.inactive' do
          expect(page).to have_content inactive_role.name
        end
      end
    end

    describe 'Search' do
      scenario 'searchable by teams' do
        fill_in 'Search', with: team.name
        click_on_search_button
        within '.roles_table.active' do
          expect(page).to have_content active_role.name
        end
      end

      scenario 'searchable by groups' do
        fill_in 'Search', with: group.name
        click_on_search_button
        within '.roles_table.active' do
          expect(page).to have_content active_role.name
        end
      end

      scenario 'searchable by roles' do
        fill_in 'Search', with: inactive_role.name
        click_on_search_button

        within '.roles_table.inactive' do
          expect(page).to have_content inactive_role.name
        end
      end
    end

    describe 'Sorting' do
      scenario 'sortable by inactive role names' do
        within '.roles_table.inactive' do
          expect(page).to have_css '.roles_name.headerSortDown'
          expect(all('.role_name_link').first).to have_text inactive_role.name
          expect(all('.role_name_link').last).to have_text inactive_role_2.name

          click_to_sort_down
          expect(page).to have_css '.roles_name.headerSortUp'
          expect(all('.role_name_link').first).to have_text inactive_role_2.name
          expect(all('.role_name_link').last).to have_text inactive_role.name
        end
      end

      scenario 'sortable by active role names' do
        first_role_in_list  = active_roles.first
        last_role_in_list   = active_roles.last

        within '.roles_table.active' do
          expect(page).to have_css '.roles_name.headerSortDown'

          expect(all('.role_name_link').first).to have_text first_role_in_list.name
          expect(all('.role_name_link').last).to have_text last_role_in_list.name

          click_to_sort_down
          expect(page).to have_css '.roles_name.headerSortUp'
          expect(all('.role_name_link').first).to have_text last_role_in_list.name
          expect(all('.role_name_link').last).to have_text first_role_in_list.name
        end
      end
    end

  end
end

def click_on_search_button
  find('.searchButton').click
  wait_for_ajax
end

def click_to_sort_down
  find('.roles_name.headerSortDown').click
  wait_for_ajax
end
