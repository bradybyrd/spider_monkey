require 'spec_helper'

feature 'Requests subtabs permissions', custom_roles: true , js: true do
  given!(:user) { create(:old_user, :not_admin_with_role_and_group) }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    permissions << 'Requests'
    permissions << 'View Requests list'
    sign_in user
  end

  describe 'Calendar tab' do
    scenario 'has access' do
      add_requests_permission('View Calendar')

      visit request_dashboard_path
      expect(request_subtabs).to have_calendar_tab

      visit calendar_months_path
      expect(page).to have_calendar
    end

    scenario 'no access' do
      visit request_dashboard_path
      expect(request_subtabs).to_not have_calendar_tab
    end
  end

  describe 'Currently Running Steps tab' do
    scenario 'has access' do
      add_requests_permission('View Currently Running Steps')

      visit request_dashboard_path
      expect(request_subtabs).to have_running_steps_tab

      visit currently_running_steps_path
      expect(page).to have_content no_steps_message
    end

    scenario 'no access' do
      visit request_dashboard_path
      expect(request_subtabs).to_not have_running_steps_tab
    end
  end

  private

  def add_requests_permission(name)
    permissions.add_from_scope 'Requests Permissions', name
  end

  def request_subtabs
    find('ul.my_dashboard_tabs')
  end

  def have_calendar_tab
    have_link 'Calendar'
  end

  def have_running_steps_tab
    have_link 'Currently Running Steps'
  end

  def have_calendar
    have_css 'table#calendar'
  end

  def no_steps_message
    'There are no Currently Running Steps'
  end
end
