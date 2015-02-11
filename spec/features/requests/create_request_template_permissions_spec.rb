require 'spec_helper'

feature 'User on a edit request page', custom_roles: true, js: true do
  given!(:app)              { create :app, :with_installed_component, name: 'Tuba mirum' }
  given!(:user)             { create(:user, :with_role_and_group, login: 'Mr. Typing', apps: [app] ) }
  given!(:team)             { create(:team, groups: user.groups) }
  given!(:development_team) { create(:development_team, team: team, app: app) }
  given!(:request)          { create(:request, name: 'Mc. Duck', apps: [app], environment: environment) }
  given!(:request_template) { create(:request_template, name: 'Scrooge the Duck', request: request) }
  given(:environment)       { app.environments.first }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  context 'with the appropriate permissions' do
    background do
      permissions << 'Create Requests' << 'Dashboard'

      sign_in(user)
    end

    describe 'creation request from template' do
      scenario 'sees the Choose Template button and creates a new request' do
        pending 'Fails randomly'

        permissions << 'View Request Templates list'
        visit new_request_path

        expect(page).not_to have_button choose_template_button

        permissions << 'Choose Template'

        visit new_request_path

        click_on choose_template_button
        wait_for_ajax

        within request_template_container do
          wait_for_ajax
        end

        select environment.name, from: 'popup_request_environment_id'
        wait_for_ajax

        within '#choose_environment_for_template' do
          request_creation = proc{ click_on create_request_from_template_button; wait_for_ajax }
          expect(&request_creation).to change{Request.count}.by(1)
        end
      end

      scenario 'user is not redirected when has no request template permissions' do
        permissions << 'View Request Templates list'
        permissions << 'Choose Template'
        visit new_request_path

        click_on choose_template_button
        wait_for_ajax

        expect(current_path).to eq new_request_path
      end

    end
  end

  def choose_template_button
    'Btn-choose-template'
  end

  def create_request_from_template_button
    'create_request_for_environment'
  end

  def create_request_from_template_popup_button
    I18n.t(:create_request)
  end

  def request_created_message
    I18n.t(:'request.notices.created')
  end

  def request_template_container
    all('#request_templates').last
  end

end
