require 'spec_helper'

feature 'Deployment window series page permissions', custom_roles: true, role_per_env: true, js: true do
  given!(:user) { create(:old_user, :not_admin_with_role_and_group) }
  given!(:environment) { create(:environment) }
  given!(:app) { create(:app, environments: [environment]) }
  given!(:team) { create(:team, groups: user.groups) }
  given!(:development_team) { create(:development_team, team: team, app: app) }
  given!(:deployment_window_series) { create(:deployment_window_series, :with_occurrences, environment_ids: [environment.id], environment_names: environment.name) }
  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    permissions <<  'View My Applications' << 'Environment' << 'Access Metadata'

    user.apps << app
    user.save(validate: false)

    sign_in user
  end

  describe 'Deployment window series index page' do
    context 'Deployment window series list' do
      scenario 'when user does not have any permissions' do
        visit deployment_window_series_index_path

        expect(page).not_to have_css('#series-lists')
        expect(page).not_to have_content(deployment_window_series.name)
      end

      scenario 'when user has permission user to view the list' do
        permissions << 'View Deployment Windows list'

        visit deployment_window_series_index_path

        expect(page).to have_css('#series-lists')
        expect(page).to have_content(deployment_window_series.name)
      end
    end

    context '"Create DWS" link' do
      background do
        permissions << 'View Deployment Windows list'
      end

      scenario 'when user does not have any deployment_window_series permissions except view list' do
        visit deployment_window_series_index_path
        expect(page).not_to have_css('.create_allow_deployment_window_series')
        expect(page).not_to have_css('.create_prevent_deployment_window_series')
      end

      scenario 'when user has "Create DWS" permission user can see "Create" link' do
        permissions << 'Create Deployment Windows Series'
        visit deployment_window_series_index_path

        expect(page).to have_css('.create_allow_deployment_window_series')
        expect(page).to have_css('.create_prevent_deployment_window_series')
        page.find('.create_allow_deployment_window_series').click
        expect(page).not_to have_content('Unauthorized')
      end
    end

    context '"Edit DWS" link' do
      background do
        permissions << 'View Deployment Windows list'
      end

      scenario 'when user does not have any deployment_window_series permissions except view list' do
        visit deployment_window_series_index_path
        expect(page).not_to have_css('.edit_deployment_window_series')
      end

      scenario 'when user has "Edit DWS" permission user can see "Edit" link' do
        permissions << 'Edit Deployment Windows Series'
        visit deployment_window_series_index_path

        expect(page).to have_css('.edit_deployment_window_series')
        page.find("#deployment_window_series_#{ deployment_window_series.id } .edit_deployment_window_series").click
        expect(page).not_to have_content('Unauthorized')
      end
    end

    context '"Update state DWS" links' do
      background do
        permissions << 'View Deployment Windows list'
      end

      scenario 'when user does not have any deployment_window_series permissions except view list' do
        visit deployment_window_series_index_path
        expect(page).not_to have_content('<<')
        expect(page).not_to have_content('>>')
      end

      scenario 'when user has "Update DWS State" permission user can see update states links' do
        permissions << 'Update Deployment Windows State'
        visit deployment_window_series_index_path

        expect(page).to have_content('>>')
        expect(page).to have_content('<<')
        expect(page).to have_content('Released')

        click_on '>>'
        expect(page).to have_content('Retired')
      end
    end

    context '"Delete" link' do
      background do
        permissions << 'View Deployment Windows list' << 'Edit Deployment Windows Series'
        deployment_window_series.archive
      end

      scenario 'when user does not have any deployment_window_series permissions except view list' do
        visit deployment_window_series_index_path
        expect(page).not_to have_css('.delete_deployment_window_series')
      end

      scenario 'when user has "Delete DWS" permission user can see "Delete" link' do
        permissions << 'Delete Deployment Windows'
        visit deployment_window_series_index_path

        expect(page).to have_css('.delete_deployment_window_series')
        page.find("#deployment_window_series_#{ deployment_window_series.id } .delete_deployment_window_series").click
        expect(page).to have_content('Deployment window was successfully deleted')
      end
    end

    context 'Edit popup' do
      context "Suspend/Resume Deployment Window" do
        background do
          permissions << 'View Deployment Windows list' << 'Edit Deployment Windows Series'
        end

        scenario 'when user has "Suspend" permission' do
          # pending 'Fails with Can not find variable: $, but works if run separately' do
          permissions << 'Suspend/Resume Deployment Window Event'

          visit deployment_window_series_index_path
          wait_for_ajax
          click_link environment.name
          click_edit_in_context_menu

          wait_for_ajax

          expect(edit_popup).to have_link 'Suspend/Resume'
        end

        scenario 'when user does not have "Suspend" permission' do
          visit deployment_window_series_index_path
          wait_for_ajax
          click_link environment.name
          click_edit_in_context_menu

          wait_for_ajax

          expect(edit_popup).not_to have_link 'Suspend/Resume'
        end
      end

      context "Move Deployment Window" do
        background do
          permissions << 'View Deployment Windows list' << 'Edit Deployment Windows Series'
        end

        scenario 'when user has "Move" permission' do
          permissions << 'Move Deployment Window Event'

          visit deployment_window_series_index_path
          wait_for_ajax
          click_link environment.name
          click_edit_in_context_menu

          wait_for_ajax

          expect(edit_popup).to have_link 'Move'
        end

        scenario 'when user does not have "Move" permission' do
          visit deployment_window_series_index_path
          wait_for_ajax
          click_link environment.name
          click_edit_in_context_menu

          wait_for_ajax

          expect(edit_popup).not_to have_link 'Move'
        end
      end
    end
  end

  describe 'List by role per environment permissions' do
    given!(:restricted_environment) { create(:environment) }
    given!(:app) { create(:app, environments: [environment, restricted_environment]) }
    given!(:restricted_role) { create(:role, permissions: []) }
    given!(:restricted_deployment_window_series) {
      create(:deployment_window_series, :with_occurrences, environment_ids: [restricted_environment.id], environment_names: restricted_environment.name)
    }
    let(:restricted_app_environment) {
      app.application_environments.where(environment_id: restricted_environment.id).first
    }

    before do
      permissions << 'View Deployment Windows list'
      user.groups.first.roles << restricted_role
      create(:team_group_app_env_role, team_group: team.team_groups.first, application_environment: restricted_app_environment, role: restricted_role)
    end

    scenario 'can see deployment windows that have list permission' do
      visit deployment_window_series_index_path

      expect(page).to have_content deployment_window_series.name
      expect(page).not_to have_content restricted_deployment_window_series.name
    end

    scenario 'cannot see deployment windows of inactive team' do
      team.deactivate!
      visit deployment_window_series_index_path

      expect(page).not_to have_content deployment_window_series.name
    end
  end

  private

  def click_edit_in_context_menu
    first('.context-menu-list span', text: 'Edit', visible: true).click
  end

  def edit_popup
    find_by_id 'facebox'
  end

end
