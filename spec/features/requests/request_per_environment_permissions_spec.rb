require 'spec_helper'

feature 'Request page permissions', js: true, custom_roles: true, role_per_env: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group, login: 'F12') }
  given!(:team) { create(:team, groups: user.groups) }
  given!(:environment) { create(:environment) }
  given!(:another_environment) { create(:environment) }

  given(:permissions) { user.groups.first.roles.first.permissions }

  given(:permissions_list) { PermissionsList.new }
  given(:permission_to) do
    {
        request: {
            requests_tab:                 create(:permission, permissions_list.permission('Requests')),
            view_requests_list:           create(:permission, permissions_list.permission('View Requests list')),
            view_created_requests_list:   create(:permission, permissions_list.permission('View created Requests list')),
            inspect:                      create(:permission, permissions_list.permission('Inspect Request')),
            create:                       create(:permission, permissions_list.permission('Create Requests')),
            edit:                         create(:permission, permissions_list.permission('Modify Requests Details')),
            auto_start:                   create(:permission, permissions_list.permission('Start Automatically'))
        }
    }
  end

  given(:basic_permissions) do
    [
      permission_to[:request][:requests_tab],
      permission_to[:request][:view_requests_list],
      permission_to[:request][:view_created_requests_list],
      permission_to[:request][:inspect],
      permission_to[:request][:view_created_requests_list]
    ]
  end

  given(:managing_permissions) do
    [
        permission_to[:request][:create],
        permission_to[:request][:edit],
        permission_to[:request][:auto_start]
    ]
  end

  background do
    User.stub(:current_user).and_return(user)
    @app = create(:app, environments: [environment, another_environment], components: [create(:component)])
    @app.application_components.last.installed_components.create(application_environment_id: @app.application_environments.last.id)
    @app.application_components.last.installed_components.create(application_environment_id: @app.application_environments.first.id)
    AssignedEnvironment.create!(environment_id: environment.id, assigned_app_id: user.assigned_apps.first.id, role: user.roles.first)
    AssignedEnvironment.create!(environment_id: another_environment.id, assigned_app_id: user.assigned_apps.first.id, role: user.roles.first)
    create(:development_team, team: team, app: @app)
    sign_in user
  end

  describe 'limit permissions by more restrictive role per environment' do
    let(:restricted_role) { create(:role, permissions: basic_permissions) }

    before do
      permissions << [basic_permissions, managing_permissions]
      user.groups.first.roles << restricted_role
      create(:team_group_app_env_role, team_group: team.team_groups.first, application_environment: @app.application_environments.first, role: restricted_role)
    end

    scenario 'validates creation of request for restricted per environment role and allows creation for non restricted' do
      visit request_dashboard_path
      create_request_with(app_name: @app.name, environment_name: environment.name)

      expect(error_explanation).to have_content I18n.t('permissions.action_not_permitted', action: 'create', subject: 'Request')

      select another_environment.name, from: 'request_environment_id'
      click_button 'Create Request'

      within '.flash_messages' do
        expect(page).to have_content I18n.t(:'request.notices.created')
      end
    end

    scenario 'validates update of request for restricted per environment role and allows update for non restricted' do
      request = create(:request, apps: [@app], environment: another_environment, owner: user)
      visit edit_request_path(request)

      click_link I18n.t(:expand)
      click_link I18n.t('request.modify_details')

      within '.request_details' do
        expect(page).not_to have_disabled_environment_field
        select environment.name, from: 'request_environment_id'
        click_button 'Update'
      end

      # Instead of checking the content of error explanation which is loaded asynchronously
      # (it causes some random assertion failures), check if the popup (request_details) displayed.
      # The popup will be displayed as long as there is an error and disappear if no error.
      expect(page).to have_css('.request_details')

      within '.request_details' do
        select another_environment.name, from: 'request_environment_id'
        click_button 'Update'
      end

      within '.flash_messages' do
        expect(page).to have_content 'Request was successfully updated.'
      end

      # No popup on success
      expect(page).not_to have_css('.request_details')

    end

    scenario 'prevents creation if user is not allowed to automatically start request on restricted environment' do
      visit request_dashboard_path

      create_request_with(app_name: @app.name, environment_name: environment.name) do
        check 'request_auto_start'
        populate_date_and_time
      end

      expect(error_explanation).to have_content I18n.t('request.validations.permit_auto_promote')

      select another_environment.name, from: 'request_environment_id'
      click_button 'Create Request'

      within '.flash_messages' do
        expect(page).to have_content I18n.t(:'request.notices.created')
      end
    end

    scenario 'prevents update if user is not allowed to automatically start request on restricted environment' do
      request = create(:request, apps: [@app], environment: another_environment, owner: user)
      visit edit_request_path(request)

      click_link I18n.t(:expand)
      click_link I18n.t('request.modify_details')

      within '.request_details' do
        expect(page).not_to have_disabled_environment_field
        select environment.name, from: 'request_environment_id'
        check 'request_auto_start'
        populate_date_and_time
        click_button 'Update'
      end

      # Instead of checking the content of error explanation which is loaded asynchronously
      # (it causes some random assertion failures), check if the popup (request_details) displayed.
      # The popup will be displayed as long as there is an error and disappear if no error.
      expect(page).to have_css('.request_details')

      within '.request_details' do
        select another_environment.name, from: 'request_environment_id'
        click_button 'Update'
      end

      within '.flash_messages' do
        expect(page).to have_content 'Request was successfully updated.'
      end

      # No popup on success
      expect(page).not_to have_css('.request_details')

    end
  end

  describe 'View Requests list' do
    let(:restricted_role) { create(:role, permissions: []) }

    before do
      permissions << basic_permissions
      user.groups.first.roles << restricted_role
      restricted_app_environment = @app.application_environments.where(environment_id: another_environment.id).first
      create(:team_group_app_env_role,
             team_group: team.team_groups.first,
             application_environment: restricted_app_environment,
             role: restricted_role)
    end

    scenario 'User cannot view requests in list if role per app_env does not have list permission' do
      allowed_request = create(:request, name: 'Allowed Request', apps: [@app], environment: environment)
      restricted_request = create(:request, name: 'Restricted Request', apps: [@app], environment: another_environment)

      visit request_dashboard_path

      expect(page).to have_content allowed_request.name
      expect(page).to_not have_content restricted_request.name
    end

    scenario 'User cannot view requests of inactive team' do
      request = create(:request, apps: [@app], environment: environment)
      team.deactivate!

      visit request_dashboard_path
      wait_for_ajax

      expect(page).not_to have_content request.name
    end
  end

  def have_disabled_environment_field
    have_field('request_environment_id', disabled: true)
  end

  def populate_date_and_time
    within '#scheduled_at' do
      fill_in 'request_scheduled_at_date', with: Date.tomorrow.strftime("%m/%d/%Y")
      select '01', from: 'request_scheduled_at_hour'
      select '00', from: 'request_scheduled_at_minute'
      select 'AM', from: 'request_scheduled_at_meridian'
    end
  end

  def create_request_with(params)
    click_link 'Btn-create'
    fill_in 'request_name', with: 'New Request'
    select params[:app_name], from: 'request_app_ids'
    select params[:environment_name], from: 'request_environment_id'
    yield if block_given?
    click_button 'Create Request'
  end

  def error_explanation
    find('.errorExplanation')
  end
end
