require 'spec_helper'

feature 'User on a environments page', custom_roles: true, js: true do
  given!(:user)         { create(:user, :non_root, :with_role_and_group, login: 'Earth') }
  given!(:environment)  { create(:environment, name: 'Mercury') }
  given!(:app)          { create(:app, environments: [environment], user_ids: [user.id]) }
  given!(:team)         { create(:team, groups: user.groups, apps: [app]) }
  given!(:permissions)  { user.groups.first.roles.first.permissions }
  given!(:permission_to) do
    {
        environment: {
            list:                   create(:permission, subject: 'Environment', action: 'list', name: 'List'),
            create:                 create(:permission, subject: 'Environment', action: 'create', name: 'Create'),
            edit:                   create(:permission, subject: 'Environment', action: 'edit', name: 'Edit'),
            delete:                 create(:permission, subject: 'Environment', action: 'delete', name: 'Delete'),
            make_active_inactive:   create(:permission, subject: 'Environment', action: 'make_active_inactive',
                                          name: 'Make Active and Inactive')
        },
        environment_tab: {
            view:                   create(:permission, subject: 'environment_tab', action: 'view', name: 'view system_tab')
        }
    }
  end

  background do
    permissions << permission_to[:environment_tab][:view]
    sign_in(user)
  end

  context 'with the appropriate permission' do
    scenario 'sees the list of the environments' do
      permissions << permission_to[:environment][:list]

      visit environments_path

      expect(page).to have_css('div#environments > table')
      expect(page).to have_content environment.name
    end

    scenario 'creates a new environment' do
      environment_name  = 'It is a jet environment'
      permissions       << permission_to[:environment][:list]
      permissions       << permission_to[:environment][:create]

      visit environments_path

      expect(page).to have_link I18n.t(:'environment.buttons.add_new')

      click_on I18n.t(:'environment.buttons.add_new')
      fill_in :environment_name, with: environment_name
      click_on I18n.t(:create)

      expect(page).to have_content environment_created_message
      expect(page).not_to have_content environment_name # because it's not assigned to app user has access to
    end

    scenario 'edits environment' do
      permissions << permission_to[:environment][:list]
      permissions << permission_to[:environment][:edit]

      visit edit_environment_path(environment)

      fill_in :environment_name, with: 'Brand new name'
      click_on I18n.t(:update)

      expect(page).to have_content environment_updated_message
      expect(page).to have_content environment.name
    end

    scenario 'makes environment active and inactive' do
      permissions << permission_to[:environment][:list]
      permissions << permission_to[:environment][:make_active_inactive]

      visit environments_path

      expect(page).not_to have_link I18n.t(:make_inactive) # because environment is used in app
    end

    scenario 'being root makes environment active and inactive' do
      grant_user_root_privileges
      environment = create :environment, name: 'To be tested'

      visit environments_path

      expect(page).to have_link I18n.t(:make_inactive)

      click_on I18n.t(:make_inactive)

      expect(page).to have_link I18n.t(:make_active)
      expect(environment.reload).not_to be_active

      click_on I18n.t(:make_active)

      expect(page).to have_link I18n.t(:make_inactive)
      expect(current_path).to eq environments_path
      expect(environment.reload).to be_active
    end

  end
end


def environment_created_message
  I18n.t(:'activerecord.notices.created', model: I18n.t('activerecord.models.environment'))
end

def environment_updated_message
  I18n.t(:'activerecord.notices.updated', model: I18n.t('activerecord.models.environment'))
end

def grant_user_root_privileges
  user.groups[0].update_column(:root, true)
end
