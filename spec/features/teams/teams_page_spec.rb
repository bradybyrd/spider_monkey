require 'spec_helper'

feature 'team page', js: true do
  let(:old_default_per_page) { AlphabeticalPaginator::DEFAULT_PER_PAGE }
  before(:all)    { AlphabeticalPaginator::DEFAULT_PER_PAGE = 2 }
  after(:all)     { AlphabeticalPaginator::DEFAULT_PER_PAGE = old_default_per_page }

  given(:user)    { create :user, :root, first_time_login: false }
  given(:team)    { create :team }
  given!(:apps)   { create_list :app, 3 }
  given!(:groups) { create_list :group, 7 }

  background do
    sign_in user
  end

  describe 'Inactive Team', custom_roles: true do
    given(:roles) { create_list :role, 3}
    given(:env)   { create :environment }

    background do
      team.apps << apps
      team.groups << groups
      Group.last.roles << roles
      App.first.environments << env
      team.update_attribute('active', false)
    end

    context 'List page' do
      background { visit teams_path }

      scenario 'expect Inactive table' do
        within('#teams > h2') do
          expect(page).to have_content('Inactive')
        end
      end

      scenario 'expect content to have Team name' do
        find_link(team.name).click
        expect(page).to have_content("Edit #{team.name}")
      end
    end

    context 'Edit page' do
      background { visit edit_team_path(team) }

      scenario 'expect disabled checkboxes' do
        within('#team_groups_assignments','.team_apps_checkbox') do
          expect(page).to have_selector("input[type='checkbox']:disabled")
        end
      end

      scenario 'expect error content' do
        find('#team_name').set('New team')
        find_button('Update Team').click
        expect(page).to have_content('You cannot update an inactive Team')
      end

      scenario 'expect page to not have link' do
        ['#select_all_team_apps', '#select_all_team_apps', '#select_all_team_groups', '#clear_all_team_groups'].each do |link_id|
          expect(page).to_not have_link(link_id)
        end
      end

      scenario 'expect disabled selects' do
        pending 'Flaky test, review after code hardening'

        find('a', text: 'Edit Roles for Team').click
        find('span', text: team.apps.map(&:name).first).click
        wait_for_ajax

        expect(page).to have_selector('select:disabled')
      end
    end
  end

  describe 'groups paginator' do
    before { visit new_team_path }

    scenario 'only part of groups visible' do
      groups_paginated = page.has_css?(group_checkboxes_selector, count: AlphabeticalPaginator::DEFAULT_PER_PAGE)

      expect(groups_paginated).to be_truthy
    end

    scenario 'paginating through the pages' do
      page_1_group_ids = groups_checkboxes.collect{|c| c['data-group-id']}
      groups_paginator_next_page; wait_for_ajax
      page_2_group_ids = groups_checkboxes.collect{|c| c['data-group-id']}

      expect(page_2_group_ids).to_not include(*page_1_group_ids)
    end
  end

  describe 'create' do
    before { visit new_team_path }

    describe 'apps table' do
      scenario 'creating a team with apps' do
        fill_in 'team_name', with: 'Hitler'
        check(app_checkbox_selector(apps.first.id))
        check(app_checkbox_selector(apps.last.id))
        click_button('Create Team'); wait_for_ajax

        expect(Team.last.apps.size).to eq(2)
      end
    end

    describe 'groups table' do
      scenario 'creating a team with groups which are paginated' do
        fill_in 'team_name', with: 'Putin Pujlo LALALALA'
        check_group_first_visible_checkbox
        groups_paginator_next_page; wait_for_ajax
        check_group_first_visible_checkbox
        click_button('Create Team'); wait_for_ajax

        expect(Team.last.groups.size).to eq(2)
      end

      scenario 'groups checkboxes are persisted when using pagination' do
        fill_in 'team_name', with: 'Long Live Democracy'
        check_group_first_visible_checkbox
        groups_paginator_next_page; wait_for_ajax
        groups_paginator_previous_page; wait_for_ajax

        expect(groups_checkboxes.first).to be_checked
      end
    end
  end

  describe 'edit' do
    before { visit edit_team_path(team) }

    describe 'team apps table' do

      scenario 'assigning an application' do
        check("development_team_#{apps.first.id}"); wait_for_ajax # ajax here

        expect(team.reload.apps.size).to eq(1)
      end

      context 'with already assigned app' do
        given(:assigned_app) { apps.first }

        before do
          assigned_app.teams << create(:team) # app should have 2 teams to be dissociatable
          team.apps = [assigned_app]
          visit edit_team_path(team)
        end

        scenario 'has the first app checked' do
          expect(app_checkbox(assigned_app)).to be_checked
        end

        scenario 'dissociate the application' do
          dissociate_app(assigned_app)
          wait_for_ajax

          expect(team.reload.apps.size).to eq(0)
        end

        def dissociate_app(app)
          uncheck("development_team_#{app.id}")
        end
      end

      scenario 'has the app checked for default team when the same app is used in another team without group' do
        default_team = create(:default_team)
        default_team.apps << apps.first
        default_team.groups << groups.first

        team_without_group =  create(:team)
        team_without_group.apps << apps.first

        visit edit_team_path(default_team)
        wait_for_ajax
        expect(app_checkbox(apps.first)).to be_checked
      end
    end

    describe 'team group table' do
      given(:group) { Group.first }

      scenario 'assigning a group' do
        check_group_first_visible_checkbox; wait_for_ajax # ajax everywhere

        expect(team.reload.groups.size).to eq(1)
      end

      context 'with assigned group' do
        before do
          group.teams << create(:team) # group should have 2 teams to be dissociatable
          team.groups = Group.all
          visit edit_team_path(team)
        end

        it 'has the all the groups checked' do
          groups_checkboxes.each do |checkbox|
            expect(checkbox).to be_checked
          end
        end

        scenario 'dissociate a group' do
          uncheck_group_checkbox(group)
          wait_for_ajax

          expect(team.reload.groups.size).to eq(Group.count - 1)
        end
      end

    end
  end

  describe 'team roles' do
    given(:environments) { create_list :environment, 2 }
    given!(:role) { create :role, name: 'Supamida' }

    before do
      team.apps = apps
      visit edit_team_path(team)
      click_link 'Edit Roles for Team'
    end

    it 'renders the apps' do
      within(team_roles_tab_selector) do
        apps_on_page = page.has_css?('.expand_team_application_link', count: team.apps.count)
        expect(apps_on_page).to be_truthy
      end
    end

    scenario 'click on app expands the application-environment-role list' do
      within(team_roles_tab_selector) do
        expand_app_roles_link = find(:css, expand_roles_link_selector(apps.first.id))
        expand_app_roles_link.click
        expect(page).to have_css '.team_applications'
      end
    end

    scenario 'click on app twice will collapse the expanded application-environment-role list' do
      within(team_roles_tab_selector) do
        expand_app_roles_link = find(:css, expand_roles_link_selector(apps.first.id))
        expand_app_roles_link.click
        expand_app_roles_link.click
        expect(page).to_not have_css '.team_applications'
      end
    end

    context 'with assigned apps and environments' do
      before do
        team.stub(:prevent_removing_app_that_result_in_app_having_no_groups)
        team.apps               = [apps[0]]
        team.groups             = [groups[0]]
        apps.first.environments = environments
        groups.each{ |g| g.roles = [role] }
      end

      let(:team_group_id)               { TeamGroup.first.id }
      let(:application_environment_id)  { ApplicationEnvironment.first.id }

      scenario 'on expanded app default role should be a "All Roles"' do
        within(team_roles_tab_selector) do
          expand_app_env_roles; wait_for_ajax
          option            = app_env_roles_select_boxes.first

          expect(option.text).to eq 'All Roles'
        end
      end

      scenario 'role per app env are displayed correctly' do
        TeamGroupAppEnvRole.create(role_id: role.id,
                                   team_group_id: team_group_id,
                                   application_environment_id: application_environment_id)

        within(team_roles_tab_selector) do
          expand_app_env_roles; wait_for_ajax
          select_box_opts   = { selected: true, app_env_id: application_environment_id, team_group_id: team_group_id }
          option            = app_env_roles_select_boxes(select_box_opts).first

          expect(option.text).to eq role.name
        end
      end

      scenario 'role per app env will be persisted after it has been selected' do
        within(team_roles_tab_selector) do
          expand_app_env_roles; wait_for_ajax
          select_box_opts   = { role_id: role.id, app_env_id: application_environment_id, team_group_id: team_group_id }
          option            = app_env_roles_select_boxes(select_box_opts).first
          option.select_option; wait_for_ajax
          expect(team.reload.roles_per_app_env).to include(role)
        end
      end

      scenario 'role per app env will deleted after "All Roles" has been selected' do
        TeamGroupAppEnvRole.create(role_id: role.id,
                                   team_group_id: team_group_id,
                                   application_environment_id: application_environment_id)
        within(team_roles_tab_selector) do
          expand_app_env_roles; wait_for_ajax
          select_box_opts   = { role_id: '', app_env_id: application_environment_id, team_group_id: team_group_id }
          option            = app_env_roles_select_boxes(select_box_opts).first
          option.select_option; wait_for_ajax
          expect(team.reload.roles_per_app_env).to_not include(role)
        end
      end
    end
  end

  # groups helpers
  def groups_checkboxes
    all(:css, group_checkboxes_selector)
  end

  def group_checkboxes_selector
    '#team_groups_assignments input'
  end

  def check_group_first_visible_checkbox
    checkbox = groups_checkboxes.first
    checkbox.set(true)
  end

  def uncheck_group_checkbox(group)
    uncheck("group_ids_#{group.id}")
  end

  def groups_paginator_next_page
    groups_paginator.last.click
  end

  def groups_paginator_previous_page
    groups_paginator.first.click
  end

  def groups_paginator
    all(:css, '.groups_alphabetic_pagination a')
  end


# apps helpers
  def app_checkbox(app)
    find("#development_team_#{app.id}")
  end

  def app_checkbox_selector(id)
    "development_team_#{id}"
  end


# roles helpers
  def team_roles_tab_selector
    '.table_of_apps_users'
  end

  def expand_roles_link_selector(app_id = nil)
    selector = '.expand_team_application_link'
    app_id ? "#{selector}[data-app-id='#{app_id}']" : selector
  end

  def app_env_roles_select_boxes(options = {})
    selected    = options[:selected]      ? '[selected]' : nil
    role        = options[:role_id]       ? "[value='#{options[:role_id]}']" : nil
    app_env     = options[:app_env_id]    ? "[data-application-environment-id='#{options[:app_env_id]}']" : nil
    team_group  = options[:team_group_id] ? "[data-team-group-id='#{options[:team_group_id]}']" : nil

    all(:css, "select.role_in_app_list#{app_env}#{team_group} option#{selected}#{role}")
  end

  def expand_app_env_roles
    find(:css, expand_roles_link_selector(apps.first.id)).click
  end
end
