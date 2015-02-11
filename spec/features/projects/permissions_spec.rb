require 'spec_helper'

feature 'Projects page permissions', js: true, custom_roles: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given!(:activity) { create(:activity) }
  given!(:activity_category) { create(:activity_category) }

  given(:activity_widget) { create(:activity_widget, name: 'requests', field: "requests") }
  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    %w(General Requests Notes).each do |tab_name|
      create(:activity_tab, name: tab_name, activity_category: activity_category)
    end

    permissions << 'Plans' << 'View Requests list'

    sign_in user
  end

  describe 'project tabs' do
    scenario 'not available' do
      visit request_projects_path
      within '#primaryNav' do
        expect(page).to have_no_content 'Projects'
      end
      within '.pageSection ul' do
        expect(page).to have_no_content 'Projects'
      end
    end

    scenario 'available' do
      permissions << 'View Projects list'
      visit request_projects_path

      within '#primaryNav' do
        expect(page).to have_link 'Projects'
      end
      within '.pageSection ul' do
        expect(page).to have_link 'Projects'
      end
    end
  end

  describe 'projects list page' do
    background { permissions << 'View Projects list' }

    scenario 'only view' do
      visit request_projects_path

      within '#request_projects .formatted_table' do
        expect(all('tbody tr').first).to have_no_link activity.name
        expect(all('tbody tr').first).to have_content activity.name
        expect(all('tbody tr td').last).to have_no_link 'Edit'
        expect(all('tbody tr td').last).to have_no_css 'a[data-method="delete"]'
      end

      within '#sidebar' do
        expect(page).to have_no_link new_activity_path(activity_category)
      end
    end

    scenario 'can delete project' do
      permissions << 'Delete Projects'
      visit request_projects_path

      all('tbody tr td').last.find('a[data-method="delete"]').click

      within '#request_projects .formatted_table' do
        expect(find('tbody')).to have_no_content activity.name
      end
    end

    scenario 'can create project' do
      permissions << 'Create Projects'
      visit request_projects_path

      click_link 'Create Project'
      expect(page.current_path).to eq new_activity_path(activity_category)
    end

    scenario 'can edit project w/o activity tabs permissions' do
      permissions << 'Edit Projects'
      visit request_projects_path

      click_link activity.name
      expect(page.current_path).to eq edit_activity_path(activity)

      expect(page).to have_no_content 'General'
      expect(page).to have_no_content 'Requests'
      expect(page).to have_no_content 'Notes'
    end
  end

  describe 'edit project page' do
    background { permissions << 'Edit Projects' }

    context 'with requests tab permission' do
      before do
        permissions << 'Edit Requests'

        Request.any_instance.stub(:is_visible?).and_return(true)
        create(:request, activity: activity)
        ActivityTab.find_by_name('Requests').activity_attributes << activity_widget
      end

      scenario 'w/o consolidation and scheduling permissions' do
        visit edit_activity_path(activity)

        expect(page).to have_css '.pageSection .selected', text: 'Requests'
        expect(page).to have_content activity.name
        expect(page).to have_no_link 'Consolidate Selected Requests'
        expect(page).not_to have_consolidate_checkboxes
        expect(page).to have_no_link 'schedule'
      end

      scenario 'with consolidation and scheduling permissions' do
        permissions << 'Schedule Requests' << 'Consolidate Requests'

        visit edit_activity_path(activity)

        expect(page).to have_link 'Consolidate Selected Requests'
        expect(page).to have_consolidate_checkboxes
        expect(page).to have_link 'schedule'
      end
    end

    context 'with general tab permission' do
      scenario 'tab available' do
        permissions << 'Edit General'
        visit edit_activity_path(activity)
        expect(page).to have_css '.pageSection .selected', text: 'General'
      end
    end

    context 'with notes tab permission' do
      scenario 'tab available' do
        permissions << 'Edit Notes'
        visit edit_activity_path(activity)
        expect(page).to have_css '.pageSection .selected', text: 'Notes'
      end
    end
  end

  private

  def have_consolidate_checkboxes
    have_css("input.request_ids[type=checkbox]")
  end
end
