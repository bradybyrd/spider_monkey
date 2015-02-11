require 'spec_helper'

feature 'User on application page', custom_roles: true, js: true do
  given!(:user) { create(:user, :with_role_and_group, apps: [app]) }
  given!(:app) { create(:app, :with_installed_component) }
  given!(:team) { create(:team, groups: user.groups) }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    create(:development_team, team: team, app: app)
    permissions << 'View Applications list' << 'Inspect Application' << 'Applications'

    sign_in user
  end

  context 'in application header section' do
    scenario 'can sort environments alphabetically' do
      permissions << 'Edit Application'

      visit app_path(app)

      expect(app_header).to have_alphabetical_environments_sorting_link
    end

    scenario 'cannot sort environments alphabetically' do
      visit app_path(app)

      expect(app_header).not_to have_alphabetical_environments_sorting_link
    end

    scenario 'can sort components alphabetically' do
      permissions << 'Edit Application'

      visit app_path(app)

      expect(app_header).to have_alphabetical_components_sorting_link
    end

    scenario 'cannot sort components alphabetically' do
      visit app_path(app)

      expect(app_header).not_to have_alphabetical_components_sorting_link
    end
  end

  context 'Create Component' do
    scenario 'can create new components' do
      permissions << 'Add/Remove Components' << 'Create Component'
      visit app_path(app)

      open_components_pop_up

      wait_for_ajax

      expect(pop_up).to have_link I18n.t('app.component.create')
    end

    scenario 'cannot create new components' do
      permissions << 'Add/Remove Components'
      visit app_path(app)

      open_components_pop_up

      wait_for_ajax

      expect(pop_up).not_to have_link I18n.t('app.component.create')
    end
  end

  context 'Reorder Components' do
    scenario 'can see Reorder Components link' do
      permissions << 'Reorder Components'

      visit app_path(app)
      wait_for_ajax

      expect(page).to have_link I18n.t('app.component.reorder')
    end

    scenario 'cannot see Reorder Components link' do
      visit app_path(app)
      wait_for_ajax

      expect(page).not_to have_link I18n.t('app.component.reorder')
    end
  end

  context 'Reorder Environments' do
    scenario 'can see Reorder Environments link' do
      permissions << 'Reorder Environments'

      visit app_path(app)
      wait_for_ajax

      expect(page).to have_link I18n.t('app.environment.reorder')
    end

    scenario 'cannot see Reorder Environments link' do
      visit app_path(app)
      wait_for_ajax

      expect(page).not_to have_link I18n.t('app.environment.reorder')
    end
  end

  context 'Add/Remove Servers to Components/Associate with Servers' do
    scenario 'can add or remove servers to/from installed component' do
      installed_component = app.installed_components.last
      permissions << 'Add/Remove Servers to Components/Associate with Servers'

      visit app_path(app)
      wait_for_ajax

      click_application_environment_link(app.application_environments.first)

      wait_for_ajax

      within installed_component_row(installed_component) do
        expect(page).to have_installed_component_checkbox(installed_component)
        expect(page).to have_link installed_component.name
      end
    end

    scenario 'cannot add or remove servers to/from installed component' do
      installed_component = app.installed_components.last
      restricted_role = create(:role, groups: user.groups)
      app_environment = app.application_environments.first
      create(:team_group_app_env_role, team_group: team.team_groups.first, application_environment: app.application_environments.first, role: restricted_role)
      permissions << 'Add/Remove Servers to Components/Associate with Servers'

      visit app_path(app)

      click_application_environment_link(app_environment)

      wait_for_ajax

      within installed_component_row(installed_component) do
        expect(page).not_to have_installed_component_checkbox(installed_component)
        expect(page).not_to have_link installed_component.name
        expect(page).to have_content installed_component.name
      end
    end
  end

  context 'Copy All Components to All Environments' do
    scenario 'can see Copy All Components to All Environments link' do
      permissions << 'Copy All Components to All Environments'

      visit app_path(app)
      wait_for_ajax

      expect(page).to have_link I18n.t('app.component.copy_all')
    end

    scenario 'cannot see Copy All Components to All Environments link' do
      visit app_path(app)
      wait_for_ajax

      expect(page).not_to have_link I18n.t('app.component.copy_all')
    end
  end

  context 'Import Application' do
    scenario 'can see Import Application link' do
      permissions << 'Import Application'

      visit apps_path

      expect(page).to have_link I18n.t('import_application')
    end

    scenario 'cannot see Import Application link' do
      visit apps_path

      expect(page).not_to have_link I18n.t('import_application')
    end
  end

  context 'Routes Tab' do
    scenario 'can see Routes tab' do
      permissions << 'View Routes'

      visit app_path(app)

      expect(page).to have_routes_tab
    end

    scenario 'cannot see Copy All Components to All Environments link' do
      visit app_path(app)
      wait_for_ajax

      expect(page).not_to have_routes_tab
    end
  end

  context 'Add New Component Template' do
    scenario 'can see Add New Component Template link' do
      permissions << 'Add New Component Template'

      visit app_path(app)
      wait_for_ajax

      expect(component_templates_list).to have_link I18n.t('app.component_template.add')
    end

    scenario 'cannot see Add New Component Template link' do
      visit app_path(app)
      wait_for_ajax

      expect(component_templates_list).not_to have_link I18n.t('app.component_template.add')
    end
  end

  context 'Sync Component Templates' do
    scenario 'can see Sync link' do
      permissions << 'Sync Component Templates'

      visit app_path(app)
      wait_for_ajax

      expect(component_templates_list).to have_link I18n.t('app.component_template.sync')
    end

    scenario 'cannot see Sync link' do
      visit app_path(app)
      wait_for_ajax

      expect(component_templates_list).not_to have_link I18n.t('app.component_template.sync')
    end
  end

  def pop_up
    find('#facebox')
  end

  def open_components_pop_up
    find('#add_remove_application_component').trigger('click')
  end

  def installed_component_row(installed_component)
    find("#installed_component_#{installed_component.id}")
  end

  def have_installed_component_checkbox(installed_component)
    have_field "installed_component_ids_#{installed_component.id}"
  end

  def click_application_environment_link(app_environment)
    find("#app_environments a[href='#{edit_app_application_environment_path(app_environment.app, app_environment)}']").click
  end

  def have_routes_tab
    have_link 'Routes'
  end

  def component_templates_list
    find_by_id 'component_templates_list'
  end

  def app_header
    find('#app_header')
  end

  def have_alphabetical_components_sorting_link
    have_css '#components_alpha_sorting', text: I18n.t('actions.edit')
  end

  def have_alphabetical_environments_sorting_link
    have_css '#environments_alpha_sorting', text: I18n.t('actions.edit')
  end
end
