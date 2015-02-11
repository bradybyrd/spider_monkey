require 'spec_helper'

feature 'Calendars page permissions', custom_roles: true do
  given!(:user)   { create(:user, :non_root, :with_role_and_group, login: 'Jupiter') }
  given!(:permissions) { user.groups.first.roles.first.permissions }
  given!(:permissions_list) { PermissionsList.new }

  given!(:view_calendars) { create(:permission, permissions_list.permission('View Calendars')) }
  given!(:view_release_calendar) { create(:permission, permissions_list.permission('View Release Calendar')) }
  given!(:view_environment_calendar) { create(:permission, permissions_list.permission('View Environment Calendar')) }
  given!(:view_dw_calendar) { create(:permission, permissions_list.permission('View Deployment Windows Calendar')) }

  background do
    permissions << view_calendars
    login_as user
  end

  describe 'Release Calendar' do
    scenario 'when user cannot view release calendar' do
      visit release_calendar_reports_path

      expect(page).to have_no_css '#filterSection'
      expect(page).to have_no_css '#chart_partial'
      expect(page).to have_no_link('Release Calendar')
    end

    scenario 'when user can view release calendar' do
      permissions << view_release_calendar
      visit release_calendar_reports_path

      expect(page).to have_css '#filterSection'
      expect(page).to have_css '#chart_partial'
      expect(page).to have_link("Release Calendar")
    end
  end

  describe 'Environment Calendar' do
    scenario 'when user cannot view environment calendar' do
      visit environment_calendar_reports_path

      expect(page).to have_no_css '#filterSection'
      expect(page).to have_no_css '#chart_partial'
      expect(page).to have_no_link("Release Calendar")
    end

    scenario 'when user can view environment calendar' do
      permissions << view_environment_calendar
      visit environment_calendar_reports_path

      expect(page).to have_css '#filterSection'
      expect(page).to have_css '#chart_partial'
      expect(page).to have_link("Environment Calendar")
    end
  end

  describe 'Deployment Windows Calendar' do
    scenario 'when user cannot view deployment windows calendar' do
      visit deployment_windows_calendar_reports_path

      expect(page).to have_no_css '#filterSection'
      expect(page).to have_no_css '#chart_partial'
      expect(page).to have_no_link("Deployment Windows Calendar")
    end

    scenario 'when user can view deployment windows calendar' do
      permissions << view_dw_calendar
      visit deployment_windows_calendar_reports_path

      expect(page).to have_css '#filterSection'
      expect(page).to have_css '#chart_partial'
      expect(page).to have_link("Deployment Windows Calendar")
    end
  end
end
