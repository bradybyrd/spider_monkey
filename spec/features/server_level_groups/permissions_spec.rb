require 'spec_helper'

feature 'Server Level Groups page permissions', js: true, custom_roles: true, role_per_env: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given!(:team) { create(:team, groups: user.groups) }
  given!(:environment) { create(:environment) }
  given!(:app) { create(:app, environments: [environment]) }
  given!(:server_aspect) { create(:server_aspect) }
  given!(:server_aspect_group) { create(:server_aspect_group, server_aspects: [server_aspect]) }
  given!(:environment_server) { create(:environment_server, server_aspect: server_aspect, environment: environment) }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    create(:development_team, team: team, app: app)
    permissions << 'Access Servers' << 'Environment'
    sign_in user
  end

  describe 'tabs' do
    context 'w/o list permission' do
      scenario 'tab not available' do
        visit servers_path

        within '.server_tabs' do
          expect(page).to have_no_link server_level_groups_tab
        end
      end
    end

    context 'with list permission' do
      scenario 'tab available' do
        permissions << 'View Server Level Groups list'
        visit servers_path

        within '.server_tabs' do
          expect(page).to have_link server_level_groups_tab
        end
      end
    end
  end

  describe 'list' do
    before { permissions << 'View Server Level Groups list' }

    context 'w/o create and edit permissions' do
      scenario 'can only see list' do
        visit server_aspect_groups_path

        within '.formatted_table' do
          expect(page).to have_no_link server_aspect_group.name
          expect(page).to have_content server_aspect_group.name
        end

        within '.Right #sidebar' do
          expect(page).to have_no_link create_server_level_group
        end
      end
    end

    context 'with create and edit permission' do
      scenario 'can edit and create items' do
        permissions << 'Create Server Level Groups' << 'Edit Server Level Groups'
        visit server_aspect_groups_path

        within '.formatted_table' do
          expect(page).to have_link server_aspect_group.name
        end

        within '.Right #sidebar' do
          expect(page).to have_link create_server_level_group
        end
      end
    end
  end

  describe 'permissions per application environments' do
    given!(:restricted_environment) { create(:environment) }
    given!(:restricted_role) { create(:role, permissions: []) }
    given(:restricted_app_environment) { app.application_environments.where(environment_id: restricted_environment.id).first }
    given(:restricted_role_permissions) { TestPermissionGranter.new(restricted_role.permissions) }

    before do
      permissions << 'View Server Level Groups list' << 'Create Server Level Groups' << 'Edit Server Level Groups'
      user.groups.first.roles << restricted_role
      user.update_assigned_apps
      app.environments << restricted_environment
      create(:team_group_app_env_role, team_group: team.team_groups.first, application_environment: restricted_app_environment, role: restricted_role)
    end

    scenario 'cannot create on restricted server aspect environment' do
      restricted_server_aspect = create(:server_aspect)
      create(:environment_server, server_aspect: restricted_server_aspect, environment: restricted_environment)
      visit server_aspect_groups_path

      create_new_server_level_group('New Server Level Group', restricted_server_aspect)

      expect(page).to have_content creation_validation_message
    end

    scenario 'cannot edit on restricted server aspect environment' do
      restricted_server_aspect = create(:server_aspect, server_level: server_aspect.server_level, parent: server_aspect.parent)
      create(:environment_server, server_aspect: server_aspect, environment: environment)
      create(:environment_server, server_aspect: restricted_server_aspect, environment: restricted_environment)

      visit server_aspect_groups_path

      update_server_level_group(server_aspect_group, server_aspect, restricted_server_aspect)

      expect(page).to have_content update_validation_message
    end

    scenario 'can create without edit permission' do
      restricted_role_permissions << 'Create Server Level Groups' << 'View Server Level Groups list'
      restricted_server_aspect = create(:server_aspect)
      create(:environment_server, server_aspect: restricted_server_aspect, environment: restricted_environment)
      name = 'New Server Level Group'

      visit server_aspect_groups_path

      create_new_server_level_group(name, restricted_server_aspect)

      expect(page).to have_content name
    end

    scenario 'can edit without create permission' do
      restricted_role_permissions << 'Edit Server Level Groups' << 'View Server Level Groups list'
      restricted_server_aspect = create(:server_aspect, server_level: server_aspect.server_level, parent: server_aspect.parent)
      create(:environment_server, server_aspect: server_aspect, environment: environment)
      create(:environment_server, server_aspect: restricted_server_aspect, environment: restricted_environment)

      visit server_aspect_groups_path

      update_server_level_group(server_aspect_group, server_aspect, restricted_server_aspect)

      expect(page).to have_link server_aspect_group.name
    end
  end

  describe 'List by role per environment permissions' do
    given!(:restricted_environment) { create(:environment) }
    given!(:app) { create(:app, environments: [environment, restricted_environment]) }
    given!(:restricted_server_aspect) { create(:server_aspect) }
    given!(:restricted_server_aspect_group) { create(:server_aspect_group, server_aspects: [restricted_server_aspect]) }
    given!(:restricted_environment_server) { create(:environment_server, server_aspect: restricted_server_aspect, environment: restricted_environment) }
    given!(:restricted_role) { create(:role, permissions: []) }
    let(:restricted_app_environment) {
      app.application_environments.where(environment_id: restricted_environment.id).first
    }

    before do
      permissions << 'View Server Level Groups list'
      user.groups.first.roles << restricted_role
      user.update_assigned_apps
      create(:team_group_app_env_role, team_group: team.team_groups.first, application_environment: restricted_app_environment, role: restricted_role)
    end

    scenario 'can see groups that have list permission' do
      visit server_aspect_groups_path

      expect(page).to have_content server_aspect_group.name
      expect(page).to_not have_content restricted_server_aspect_group.name
    end

    scenario 'cannot see groups of inactive team' do
      team.deactivate!
      visit server_aspect_groups_path

      expect(page).not_to have_content server_aspect_group.name
    end
  end

  def creation_validation_message
    I18n.t('permissions.action_not_permitted', action: 'create', subject: 'Server aspect group')
  end

  def update_validation_message
    I18n.t('permissions.action_not_permitted', action: 'edit', subject: 'Server aspect group')
  end

  def create_server_level_group
    'Create_server_level_group'
  end

  def server_instances_select_box
    'server_aspect_ids'
  end

  def server_level_select_box
    'server_level_id'
  end

  def server_level_groups_tab
    'Server Level Groups'
  end

  def create_new_server_level_group(name, server_aspect)
    click_link create_server_level_group
    fill_in 'Name', with: name
    select server_aspect.server_level.name, from: server_level_select_box
    select server_aspect.full_name, from: server_instances_select_box
    click_button I18n.t(:create_server_level_group)
    wait_for_ajax
  end

  def update_server_level_group(server_aspect_group, old_server_aspect, new_server_aspect)
    click_link server_aspect_group.name
    unselect old_server_aspect.full_name, from: server_instances_select_box
    select new_server_aspect.full_name, from: server_instances_select_box
    click_button "Update #{server_aspect_group.name}"
    wait_for_ajax
  end
end
