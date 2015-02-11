require 'spec_helper'

feature 'Reports page permissions', custom_roles: true do
  given!(:user) { create :user, :with_role_and_group }
  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }
  given(:view_reports_tab_permission) { 'Reports' }
  given(:view_process_permission) { 'View Process' }
  given(:view_volume_report_permission) { 'View Volume Report' }
  given(:view_time_to_complete_report_permission) { 'View Time to Complete Report' }
  given(:view_problem_trend_report_permission) { 'View Problem Trend Report' }
  given(:view_time_to_problem_report_permission) { 'View Time of Problem Report' }
  given(:view_maps_reports_permission) { 'View Maps' }
  given(:view_component_versions_map_permission) { 'View Component Versions Map by Application' }
  given(:view_properties_map_permission) { 'View Properties Map by Environment/Application' }
  given(:view_servers_map_by_app_permission) { 'View Servers Map by Application' }
  given(:view_server_map_permission) { 'View Server Map' }
  given(:view_app_component_summary_map_permission) { 'View Application Component Summary' }
  given(:view_access_permission) { 'View Access' }
  given(:view_roles_map_permission) { 'View Roles by Team/Group/User' }

  background do
    permissions << 'Dashboard'
    sign_in user
  end

  describe 'Reports tab' do
    scenario 'not available when user doesn\'t have :view permissions' do
      permissions = []

      visit dashboard_path

      within '#primaryNav' do
        expect(page).not_to have_content 'Reports'
      end
    end

    scenario 'available when user does have :view permissions' do
      permissions << view_reports_tab_permission

      visit dashboard_path

      within '#primaryNav' do
        expect(page).to have_content 'Reports'
      end
    end

    context 'user has Reports tab permission but does not have any nested permission' do
      scenario 'user sees error message' do
        permissions << view_reports_tab_permission

        visit(reports_path(report_type: 'time_to_complete_report'))

        expect(page).to have_no_access_message
      end
    end

    context 'user has Reports tab permission but does not have any nested permission' do
      scenario 'user sees error message' do
        permissions << view_reports_tab_permission

        visit(reports_path(report_type: 'problem_trend_report'))

        expect(page).to have_no_access_message
      end
    end

    context 'user has Reports tab permission but does not have any nested permission' do
      scenario 'user sees error message' do
        permissions << view_reports_tab_permission

        visit(reports_path(report_type: 'time_to_problem_report'))

        expect(page).to have_no_access_message
      end
    end

    context 'user has Reports tab permission but does not have any nested permission' do
      scenario 'user sees error message' do
        permissions << view_reports_tab_permission

        visit(reports_path(report_type: 'volume_report'))

        expect(page).to have_no_access_message
      end
    end
  end


  describe 'Process subtab' do
    scenario 'not available when user doesn\'t have :process_reports permission' do
      permissions << view_reports_tab_permission
      permissions << view_maps_reports_permission

      visit maps_path

      within '.pageSection' do
        expect(page).not_to have_content 'Process'
      end
    end

    scenario 'available when user does have :process_reports permission' do
      permissions << view_reports_tab_permission
      permissions << view_process_permission

      visit reports_path

      within '.pageSection' do
        expect(page).to have_content 'Process'
      end
    end

    describe 'Volume Report link' do
      scenario 'not available when user doesn\'t have :volume_report permission' do
        permissions << view_reports_tab_permission
        permissions << view_process_permission

        visit reports_path

        expect(page).not_to have_css '#sidebar a', text: 'Volume Report'
      end

      scenario 'available when user does have :volume_report permission' do
        permissions << view_reports_tab_permission
        permissions << view_process_permission
        permissions << view_volume_report_permission

        visit reports_path

        expect(page).to have_css '#sidebar a', text: 'Volume Report'
      end
    end

    describe 'Time to Complete Report link' do
      scenario 'not available when user doesn\'t have :time_to_complete_report permission' do
        permissions << view_reports_tab_permission
        permissions << view_process_permission

        visit reports_path

        within '#sidebar' do
          expect(page).not_to have_content 'Time to Complete Report'
        end
      end

      scenario 'available when user does have :time_to_complete_report permission' do
        permissions << view_reports_tab_permission
        permissions << view_process_permission
        permissions << view_time_to_complete_report_permission

        visit reports_path

        within '#sidebar' do
          expect(page).to have_content 'Time to Complete Report'
        end
      end
    end

    describe 'Problem Trend Report link' do
      scenario 'not available when user doesn\'t have :problem_trend_report permission' do
        permissions << view_reports_tab_permission
        permissions << view_process_permission

        visit reports_path

        within '#sidebar' do
          expect(page).not_to have_content 'Problem Trend Report'
        end
      end

      scenario 'available when user does have :problem_trend_report permission' do
        permissions << view_reports_tab_permission
        permissions << view_process_permission
        permissions << view_problem_trend_report_permission

        visit reports_path

        within '#sidebar' do
          expect(page).to have_content 'Problem Trend Report'
        end
      end
    end

    describe 'Time of Problem Report link' do
      scenario 'not available when user doesn\'t have :time_to_problem_report permission' do
        permissions << view_reports_tab_permission
        permissions << view_process_permission

        visit reports_path

        within '#sidebar' do
          expect(page).not_to have_content 'Time of Problem Report'
        end
      end

      scenario 'available when user does have :time_to_problem_report permission' do
        permissions << view_reports_tab_permission
        permissions << view_process_permission
        permissions << view_time_to_problem_report_permission

        visit reports_path

        within '#sidebar' do
          expect(page).to have_content 'Time of Problem Report'
        end
      end
    end
  end

  describe 'Maps subtab' do
    scenario 'not available when user doesn\'t have :view permissions' do
      permissions << view_reports_tab_permission
      permissions << view_process_permission

      visit reports_path

      within '.pageSection' do
        expect(page).not_to have_content 'Maps'
      end
    end

    scenario 'available when user does have :view permissions' do
      permissions << view_reports_tab_permission
      permissions << view_maps_reports_permission
      permissions << 'Dashboard'

      visit maps_path

      within '.pageSection' do
        expect(page).to have_content 'Maps'
      end
    end

    describe 'Component Versions Map by Application link' do
      scenario 'not available when user doesn\'t have :process_reports permission' do
        permissions << view_reports_tab_permission
        permissions << view_maps_reports_permission

        visit maps_path

        within '#sidebar' do
          expect(page).not_to have_content 'Component Versions Map by Application'
        end
      end

      scenario 'available when user does have :process_reports permission' do
        permissions << view_reports_tab_permission
        permissions << view_maps_reports_permission
        permissions << view_component_versions_map_permission

        visit maps_path

        within '#sidebar' do
          expect(page).to have_content 'Component Versions Map by Application'
        end
      end
    end

    describe 'Properties Map by Environment/Application link' do
      scenario 'not available when user doesn\'t have :view_properties_map_permission permission' do
        permissions << view_reports_tab_permission
        permissions << view_maps_reports_permission

        visit maps_path

        within '#sidebar' do
          expect(page).not_to have_content 'Properties Map by Environment/Application'
        end
      end

      scenario 'available when user does have : permission' do
        permissions << view_reports_tab_permission
        permissions << view_maps_reports_permission
        permissions << view_properties_map_permission

        visit maps_path

        within '#sidebar' do
          expect(page).to have_content 'Properties Map by Environment/Application'
        end
      end
    end

    describe 'Servers Map by Application  link' do
      scenario 'not available when user doesn\'t have :view_servers_map_by_app_permission permission' do
        permissions << view_reports_tab_permission
        permissions << view_maps_reports_permission

        visit maps_path

        within '#sidebar' do
          expect(page).not_to have_content 'Servers Map by Application '
        end
      end

      scenario 'available when user does have :view_servers_map_by_app_permission permission' do
        permissions << view_reports_tab_permission
        permissions << view_maps_reports_permission
        permissions << view_servers_map_by_app_permission

        visit maps_path

        within '#sidebar' do
          expect(page).to have_content 'Servers Map by Application '
        end
      end
    end

    describe 'Servers Map link' do
      scenario 'not available when user doesn\'t have :view_server_map_permission permission' do
        permissions << view_reports_tab_permission
        permissions << view_maps_reports_permission

        visit maps_path

        within '#sidebar' do
          expect(page).not_to have_content 'Servers Map'
        end
      end

      scenario 'available when user does have :view_server_map_permission permission' do
        permissions << view_reports_tab_permission
        permissions << view_maps_reports_permission
        permissions << view_server_map_permission

        visit maps_path

        within '#sidebar' do
          expect(page).to have_content 'Servers Map'
        end
      end
    end

    describe 'Application Component Summary link' do
      scenario 'not available when user doesn\'t have :view_app_component_summary_map_permission permission' do
        permissions << view_reports_tab_permission
        permissions << view_maps_reports_permission

        visit maps_path

        within '#sidebar' do
          expect(page).not_to have_content 'Application Component Summary'
        end
      end

      scenario 'available when user does have :view_app_component_summary_map_permission permission' do
        permissions << view_reports_tab_permission
        permissions << view_maps_reports_permission
        permissions << view_app_component_summary_map_permission

        visit maps_path

        within '#sidebar' do
          expect(page).to have_content 'Application Component Summary'
        end
      end
    end
  end

  describe 'View Access subtab' do
    scenario 'not available when user does not have :view_access permission' do
      permissions << view_reports_tab_permission
      permissions << view_process_permission

      visit reports_path

      within '.pageSection' do
        expect(page).not_to have_content I18n.t('reports.view_access.title')
      end
    end

    scenario 'available when user have :view_access permission' do
      permissions << view_reports_tab_permission
      permissions << view_access_permission

      visit reports_access_index_path

      expect(page.title).to eq I18n.t('reports.view_access.title')
    end

    describe 'Roles by Team/Group/User' do
      scenario 'not available when user doesn\'t have :view_roles_map permission' do
        permissions << view_reports_tab_permission
        permissions << view_access_permission

        visit reports_access_index_path

        within '#sidebar' do
          expect(page).not_to have_content I18n.t('reports.view_access.roles_map.title')
        end
      end

      scenario 'available when user does have :view_roles_map permission' do
        permissions << view_reports_tab_permission
        permissions << view_access_permission
        permissions << view_roles_map_permission

        visit reports_access_roles_map_path

        within '#sidebar' do
          expect(page).to have_content I18n.t('reports.view_access.roles_map.title')
        end
        expect(page.title).to eq I18n.t('reports.view_access.roles_map.title')
      end
    end
  end

  def have_no_access_message
    have_content(I18n.t(:'activerecord.errors.no_access_to_view_page'))
  end
end
