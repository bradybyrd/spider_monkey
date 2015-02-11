require 'spec_helper'

feature 'Dashboard permissions', custom_roles: true , js: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    permissions << 'Dashboard'
    sign_in user
  end

  describe 'View My Servers' do
    scenario 'no access' do
      expect(page).not_to have_my_servers_tab
    end

    context 'has access' do
      before do
        permissions << 'View My Servers'
      end

      scenario 'can see servers tab' do
        visit root_path
        expect(page).to have_my_servers_tab
      end

      context 'create server button' do
        scenario 'can see create button' do
          permissions << 'Create Server'
          visit root_path
          expect(page).to have_create_server_button
        end

        scenario 'cannot see create button' do
          visit root_path
          expect(page).not_to have_create_server_button
        end
      end
    end
  end

  describe 'View My Applications' do
    scenario 'no access' do
      expect(page).not_to have_my_applications_tab
    end

    context 'has access' do
      before do
        permissions << 'View My Applications'
      end

      scenario 'can see applications tab' do
        visit root_path
        expect(page).to have_my_applications_tab
      end

      context 'create application button' do
        scenario 'can see create button' do
          permissions << 'Create Application'
          visit root_path
          expect(page).to have_create_application_button
        end

        scenario 'cannot see create button' do
          visit root_path
          expect(page).not_to have_create_application_button
        end
      end

      context 'edit application link' do
        before do
          @env = create(:environment )
          @team = create(:team, groups: user.groups)
          @app = create(:app, environments: [@env], teams:[@team])
        end

        scenario 'can see edit link' do
          permissions << 'Edit Application'
          visit root_path
          expect(page).to have_edit_link
        end

        scenario 'cannot see edit link' do
          visit root_path
          expect(page).not_to have_edit_link
        end
      end

      context 'releases links' do
        scenario 'can see release link' do
          permissions << 'Inspect Plans' << 'View created Requests list' << 'View Requests list'
          environment = create(:environment)
          team = create(:team, groups: user.groups)
          app = create(:app, environments: [environment], teams:[team])
          release = create(:release)
          plan_template = create(:plan_template, stages: [create(:plan_stage)])
          plan = create(:plan, plan_template: plan_template, release: release)
          request = create(:request, {
            environment: app.environments.first, owner: user, apps: [app],
            plan_member: create(:plan_member, plan: plan, stage: plan.stages.first),
            release: release
          })

          visit root_path

          expect(page).to have_link release.name
        end
      end
    end
  end

  describe 'My Requests tab' do
    context 'without View My request permission' do
      scenario 'is not shown' do
        expect(page).not_to have_my_requests_tab
      end
    end

    context 'with View My request permission' do
      scenario 'is shown' do
        permissions << 'View My Requests'

        visit root_path
        expect(page).to have_my_requests_tab
      end
    end
  end

  private

  def have_create_server_button
    have_button 'Create Server'
  end

  def have_my_servers_tab
    have_link 'My Servers'
  end

  def have_my_applications_tab
    have_link 'My Applications'
  end

  def have_my_requests_tab
    have_link 'My Requests'
  end

  def have_create_application_button
    have_button 'Create Application'
  end

  def have_edit_link
    have_link 'Edit'
  end
end