require 'spec_helper'

feature 'User on a edit request page', custom_roles: true, js: true do
  given!(:user)             { create(:user, :with_role_and_group, login: 'Mr. Typing') }
  given!(:team)             { create(:team, groups: user.groups) }
  given!(:app)              { create :app, :with_installed_component, name: 'Tuba mirum', environments: [create(:environment)] }
  given!(:development_team) { create(:development_team, team: team, app: app) }
  given!(:request)          { create(:request, name: 'Mc. Duck', apps: [app], environment: environment) }
  given(:environment)       { app.environments.first }
  given!(:procedure)        { create(:procedure, apps: [app]) }
  given!(:procedure_step)   { create(:step, floating_procedure: procedure, request: nil, owner: user) }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  context 'with the appropriate permissions' do
    background do
      permissions << 'Inspect Request' << 'Inspect Steps' << 'Add Procedure' << 'View created Requests list'
      sign_in(user)
    end

    describe 'Add procedure to request' do
      scenario 'can add procedure to request' do
        visit edit_request_path(request)
        wait_for_ajax

        expect(page.title).to include request.name

        click_on add_procedure_button
        wait_for_ajax

        within "#edit_procedure_#{procedure.id}" do
          click_on "Add"
        end

        wait_for_ajax

        expect(steps_list).to have_content procedure.name
      end
    end

    describe 'Edit procedure' do
      scenario "cannot edit procedure's name and description" do
        step_procedure = create(:step, procedure: true, request: request)
        visit edit_request_path(request)

        wait_for_ajax

        expect(steps_list).to have_content step_procedure.name
        expect(steps_list).to have_content step_procedure.description

        expect(steps_list).to_not have_link step_procedure.name
        expect(steps_list).to_not have_link step_procedure.description
      end

      scenario "can edit procedure's name and description" do
        permissions << 'Edit Procedure'
        step_procedure = create(:step, procedure: true, request: request)
        visit edit_request_path(request)

        wait_for_ajax

        expect(steps_list).to have_link step_procedure.name
        expect(steps_list).to have_link step_procedure.description
      end
    end

    describe 'Edit execution condition' do
      scenario "cannot edit procedure's execution condition" do
        procedure = create(:step, procedure: true, request: request)
        visit edit_request_path(request)

        wait_for_ajax

        expect(steps_list).to have_execution_condition_image
        expect(steps_list).not_to have_execution_condition_link(procedure)
      end

      scenario "can edit procedure's execution condition" do
        permissions << 'Edit Execution Conditions for Procedure'
        procedure = create(:step, procedure: true, request: request)
        visit edit_request_path(request)

        wait_for_ajax

        expect(steps_list).to have_execution_condition_link(procedure)
      end
    end
  end

  def add_procedure_button
    'Add procedure'
  end

  def steps_list
    find('#steps_list')
  end

  def have_execution_condition_image
    have_css('img[alt="condition"]')
  end

  def have_execution_condition_link(procedure)
    have_css("#execution_condition_#{procedure.id} img[alt='condition']")
  end
end
