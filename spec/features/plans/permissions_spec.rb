require 'spec_helper'

feature 'Plans page permissions', js: true, custom_roles: true, role_per_env: true do
  given!(:environment) { create(:environment) }
  given!(:app) { create(:app, environments: [environment]) }
  given!(:route) { create(:route, app: app) }
  given!(:route_gate) { create(:route_gate, route: route, environment: environment) }
  given!(:user) { create(:user, :non_root, :with_role_and_group, apps: [app]) }
  given!(:team) { create(:team, groups: user.groups) }
  given!(:development_team) { create(:development_team, team: team, app: app) }
  given!(:plan_template) { create(:plan_template, stages: [create(:plan_stage)]) }
  given!(:plan) { create(:plan, plan_template: plan_template) }
  given!(:request) { create(:request, environment: app.environments.first, owner: user, apps: [app], plan_member: create(:plan_member, plan: plan, stage: plan.stages.first)) }
  given!(:ticket) { create(:ticket, plans: [plan]) }
  given!(:plan_route) { create(:plan_route, plan: plan, route: route) }
  given!(:constraint) { create(:constraint, constrainable: route_gate, governable: plan.plan_stage_instances.first) }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    permissions << 'Dashboard'
    sign_in user
  end

  describe 'plan tabs' do
    scenario 'tab not visible w/o main tab permission' do
      visit root_path

      within '.leftNavGroup' do
        expect(page).to have_no_content 'Plans'
      end
    end

    scenario 'main tab visible and subtab not visible with main tab permission' do
      permissions << 'Plans'
      visit root_path

      within '.leftNavGroup' do
        expect(page).to have_link 'Plans'
      end

      within '.drop_down.plans' do
        expect(page).to have_no_content 'Plans'
      end
    end

    scenario 'subtab visible with list permission' do
      permissions << 'Plans' << 'View Plans list'
      visit root_path

      within '.drop_down.plans' do
        expect(page).to have_link 'Plans'
      end
    end
  end

  describe 'list' do
    before do
      permissions << 'Plans' << 'View Plans list' << 'View Requests list'
    end

    scenario 'only list is visible' do
      visit plans_path

      within '.formatted_table' do
        expect(page).to have_no_link plan.name
        expect(page).to have_content plan.name

        within '.plan_status_flowchart' do
          expect(page).to have_no_link plan.aasm_state.capitalize
          expect(page).to have_content plan.aasm_state.capitalize
        end
      end

      within '.Right #sidebar' do
        expect(page).to have_no_link 'Create plan'
      end
    end

    context 'with inspect and create permissions' do
      scenario 'able to create and inspect' do
        permissions << 'Create Plan' << 'Inspect Plans'
        visit plans_path

        within '.formatted_table' do
          expect(page).to have_link plan.name

          within '.plan_status_flowchart' do
            expect(page).to have_link plan.aasm_state.capitalize
          end
        end

        within '.Right #sidebar' do
          expect(page).to have_link 'Create plan'
        end
      end
    end
  end

  describe 'inspect' do
    describe 'plan tab' do
      before do
        permissions << 'Inspect Plans' << 'View Plans list'
      end

      scenario 'plan related tabs not available' do
        visit plan_path(plan)

        within '.inspection_tabs' do
          expect(page).to have_link "#{plan.name} - #{plan.plan_template.template_type_label}"
          expect(page).to have_no_link 'Tickets'
          expect(page).to have_no_link 'Routes'
        end
      end

      scenario 'can only view details' do
        visit plan_path(plan)

        within '.edit_env_app_dates' do
          expect(page).to have_no_link app.name
          expect(page).to have_content app.name
        end

        expect(page).to have_no_content I18n.t('edit_plan_details')

        within '.Right #sidebar' do
          expect(page).to have_no_link 'Btn-assign-app-route'
          expect(page).to have_no_button 'Ticket Summary Report'

          within '.state_manipulator' do
            expect(page).to have_no_link 'Plan'
            expect(page).to have_no_link 'Life_c_cancel'
            expect(page).to have_no_link 'Life_c_delete'
          end
        end
      end

      scenario 'can assign routes and view ticket summary' do
        permissions << 'View Tickets Summary Report' << 'Assign App Route'
        visit plan_path(plan)

        within '.Right #sidebar' do
          expect(page).to have_link 'Btn-assign-app-route'
          expect(page).to have_button 'Ticket Summary Report'
        end
      end

      context 'has [plan, cancel, delete] permissions' do
        scenario 'can change states w/o "start" permission' do
          permissions << 'Plan Plan' << 'Delete Plan' << 'Cancel Plan'
          visit plan_path(plan)

          within '.state_manipulator' do
            expect(page).to have_link 'Plan'
            expect(page).to have_link 'Life_c_cancel'
            expect(page).to have_link 'Life_c_delete'
          end

          click_link 'Plan'

          within '.state_manipulator' do
            expect(page).not_to have_change_state_button('Start Plan')
          end
        end

        context 'with "start" permission' do
          before { permissions << 'Plan Plan' << 'Start Plan' }

          scenario 'can start plan w/o [lock, hold, complete]' do
            visit plan_path(plan)

            change_state_button('Plan Plan').click
            change_state_button('Start Plan').click

            expect(page).not_to have_change_state_button('Lock Plan')
            expect(page).not_to have_change_state_button('Hold Plan')
            expect(page).not_to have_change_state_button('Complete Plan')
          end

          context 'with [lock, hold, complete]' do
            before do
              permissions << 'Lock Plan' << 'Hold Plan' << 'Complete Plan'
            end

            scenario 'can lock, hold and complete plan w/o [archive_unarchive, reopen]' do
              visit plan_path(plan)

              change_state_button('Plan Plan').click
              change_state_button('Start Plan').click

              expect(page).to have_change_state_button('Lock Plan')
              expect(page).to have_change_state_button('Hold Plan')
              expect(page).to have_change_state_button('Complete Plan')

              change_state_button('Complete Plan').click

              expect(page).not_to have_change_state_button('Archive Plan')
            end

            scenario 'can archive and reopen plan with [archive_unarchive, reopen]' do
              permissions << 'Archive Plan' << 'Reopen Plan'
              visit plan_path(plan)

              click_link 'Plan'
              click_link 'Start_plans'
              click_link 'Complete'

              within '.state_manipulator' do
                expect(page).to have_link 'Archive'
                expect(page).to have_link 'Btn-reopen-plan'
              end
            end
          end
        end
      end
    end

    describe 'tickets tab' do
      before { permissions << 'View Tickets list' }

      scenario 'can view list' do
        visit tickets_plan_path(plan)

        within '.inspection_tabs' do
          expect(page).to have_link 'Tickets'
        end

        within '.ticketList' do
          expect(page).to have_no_link ticket.name
          expect(page).to have_content ticket.name
          expect(page).to have_no_link 'Bin_empty'
        end
      end

      context 'with delete and edit permissions' do
        scenario 'able to edit and delete' do
          permissions << 'Edit Tickets' << 'Delete Tickets'
          visit tickets_plan_path(plan)

          within '.ticketList' do
            expect(page).to have_link ticket.name
            expect(page).to have_link 'Bin_empty'
          end
        end
      end
    end

    describe 'routes tab' do
      before { permissions << 'View Routes list' }

      describe 'list' do
        scenario 'can view list' do
          visit plan_plan_routes_path(plan)

          within '.plan_routeList' do
            expect(page).to have_no_link 'Configure'
            expect(page).to have_no_link plan_route.route_name
            expect(page).to have_content plan_route.route_name
            expect(page).to have_no_link 'Bin_empty'
          end
        end

        context 'with [inspect, delete, configure] permissions' do
          scenario 'can manage plan routes' do
            permissions << 'Inspect Route' << 'Configure Route' << 'Delete Route from Plan'
            visit plan_plan_routes_path(plan)

            within '.plan_routeList' do
              expect(page).to have_link 'Configure'
              expect(page).to have_link plan_route.route_name
              expect(page).to have_link 'Bin_empty'
            end
          end
        end
      end

      describe 'inspect' do
        before do
          create(:route_gate, route: route, environment: create(:environment))
          permissions << 'Inspect Route'
        end

        scenario 'can only view constraints' do
          visit plan_plan_route_path(plan, plan_route)

          within '.plan_stage_instance_level .plan_stage_instance_constraints' do
            expect(page).to have_content environment.name
            expect(page).not_to have_css('.delete_route_gate')
          end

          within '#route_gates_list' do
            expect(page).to have_no_button 'Assign to Stage'
          end
        end

        context 'with configure permission' do
          scenario 'can assign and deassign constraints' do
            permissions << 'Configure Route'
            visit plan_plan_route_path(plan, plan_route)

            within '.plan_stage_instance_level .plan_stage_instance_constraints' do
              expect(page).to have_content environment.name
              expect(page).to have_css('.delete_route_gate')
            end

            within '#route_gates_list' do
              expect(page).to have_button 'Assign to Stage'
            end
          end
        end
      end
    end
  end

  describe 'list requests per environment' do
    given!(:restricted_environment) { create(:environment) }
    given!(:app) { create(:app, environments: [environment, restricted_environment]) }
    given!(:restricted_route_gate) { create(:route_gate, route: route, environment: restricted_environment) }
    given!(:constraint) { create(:constraint, constrainable: restricted_route_gate, governable: plan.plan_stage_instances.first) }
    given!(:restricted_role) { create(:role, permissions: []) }
    given!(:restricted_request) {
      create(:request, {
        environment: restricted_environment,
        owner: user,
        apps: [app],
        plan_member: create(:plan_member, plan: plan, stage: plan.stages.first)
      })
    }
    let(:restricted_app_environment) {
      app.application_environments.where(environment_id: restricted_environment.id).first
    }

    before do
      permissions << 'Plans' << 'Inspect Plans' << 'View Plans list' << 'View Requests list' << 'View created Requests list'
      user.groups.first.roles << restricted_role
      create(
        :team_group_app_env_role,
        team_group: team.team_groups.first,
        application_environment: restricted_app_environment,
        role: restricted_role
      )
    end

    scenario 'can see request that have list permission' do
      visit plan_path(plan)
      wait_for_ajax

      expect(page).to have_content request.name
      expect(page).not_to have_content restricted_request.name
    end

    scenario 'cannot see request of inactive team' do
      team.deactivate!
      visit plan_path(plan)
      wait_for_ajax

      expect(page).not_to have_content request.name
    end
  end

  def css_class_name(name)
    name.downcase.gsub(' ', '_')
  end

  def have_change_state_button(name)
    have_css(".state_manipulator .#{ css_class_name(name) }")
  end

  def change_state_button(name)
    find(".state_manipulator .#{ css_class_name(name) }")
  end
end

feature 'Runs details on plans page', js: true, custom_roles: true do
  given!(:environment) { create(:environment) }
  given!(:app) { create(:app, environments: [environment]) }
  given!(:route) { create(:route, app: app) }
  given!(:route_gate) { create(:route_gate, route: route, environment: environment) }
  given!(:user) { create(:user, :non_root, :with_role_and_group, apps: [app]) }
  given!(:team) { create(:team, groups: user.groups) }
  given!(:development_team) { create(:development_team, team: team, app: app) }
  given!(:plan_stage) { create(:plan_stage) }
  given!(:plan_template) { create(:plan_template, stages: [plan_stage]) }
  given!(:plan) { create(:plan, plan_template: plan_template) }
  given!(:run) { create(:run, plan: plan, requestor: user, owner: user, plan_stage: plan_stage) }
  given!(:plan_member) { create(:plan_member, plan: plan, stage: plan.stages.first, run: run) }
  given!(:request) { create(:request, environment: app.environments.first, owner: user, apps: [app], plan_member: plan_member) }
  given!(:ticket) { create(:ticket, plans: [plan]) }
  given!(:plan_route) { create(:plan_route, plan: plan, route: route) }
  given!(:constraint) { create(:constraint, constrainable: route_gate, governable: plan.plan_stage_instances.first) }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  scenario 'user without "Runs" permissions is not able to Inspect Runs' do
    permissions << 'Dashboard' << 'Plans' << 'Inspect Plans' << 'View Plans list' <<
                   'Manage Plans' << 'View Requests list' << 'Inspect Request' <<
                   'View created Requests list'
    sign_in user
    visit plan_path(plan)

    within "#request_row_#{ request.id }" do
      click_on run.name
    end

    expect(page).to have_no_access_message
  end

  scenario 'user with all manage "Runs" permissions except "Delete" should be able to "Plan run"' do
    permissions << 'Dashboard' << 'Plans' << 'Inspect Plans' << 'View Plans list'
    permissions << 'Manage Plans' << 'View Requests list' << 'Inspect Request' << 'Inspect Runs'
    permissions << 'Create Runs' << 'Edit Runs' << 'Move Requests' << 'Add to Run'
    permissions << 'Drop from Run' << 'Reorder Run' << 'Plan Run' << 'Start Run'
    permissions << 'Hold Run' << 'Cancel Run' << 'View created Requests list'
    sign_in user
    visit plan_path(plan)

    within "#request_row_#{ request.id }" do
      click_on run.name
    end

    within '.run_state_buttons' do
      click_on 'Plan Run'
    end

    expect(page).not_to have_no_access_message
  end

  def have_no_access_message
    have_content(I18n.t(:'activerecord.errors.no_access_to_view_page'))
  end
end
