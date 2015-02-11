require 'spec_helper'

feature 'Request Templates page permissions', custom_roles: true, role_per_env: true, js: true do
  given!(:user)             { create(:user, :with_role_and_group, apps: [app] ) }
  given!(:team)             { create(:team, groups: user.groups) }
  given!(:app)              { create :app, :with_installed_component, environments: [environment]  }
  given!(:development_team) { create(:development_team, team: team, app: app) }
  given!(:request)          { create(:request, apps: [app], environment: environment) }
  given!(:request_template) { create(:request_template, request: request) }
  given(:environment)       { create(:environment) }

  given!(:permissions)      { user.groups.first.roles.first.permissions }
  given!(:basic_permissions) { [
      create(:permission, name: 'View applications', action: :view, subject: :my_applications ),
      create(:permission, name: 'Environment tab view', action: :view, subject: :environment_tab),
      create(:permission, name: 'Metadata', action: :view, subject: :metadata)
    ] }

  given(:list_request_templates_permission) { create(:permission, name: 'View Request Templates list', action: :list, subject: 'RequestTemplate') }
  given(:edit_request_template_permission) { create(:permission, name: 'Edit Request Templates', action: :edit, subject: 'RequestTemplate') }
  given(:update_state_request_template_permission) { create(:permission, name: 'Update Request Templates State', action: :update_state, subject: 'RequestTemplate') }
  given(:delete_request_template_permission) { create(:permission, name: 'Delete Request Templates', action: :delete, subject: 'RequestTemplate') }
  given(:inspect_request_templates_permission) { create(:permission, name: 'Inspect Request Templates', action: :inspect, subject: 'RequestTemplate') }

  background do
    permissions << basic_permissions

    sign_in user
  end

  describe 'Request Templates index page' do
    context 'Request Templates list' do
      scenario 'when user does not have any request_template permissions' do
        visit request_templates_path

        expect(page).not_to have_css('#request_templates')
        expect(page).to have_content(I18n.t('activerecord.errors.no_access_to_view_page'))
      end

      scenario 'when user has "list request_templates" permission user can view request_templates list' do
        permissions << list_request_templates_permission

        visit request_templates_path

        expect(page).to have_css('#request_templates')
        expect(page).to have_content(request_template.name)
      end
    end

    context 'Inspect Request Templates' do
      background do
        permissions << list_request_templates_permission
      end

      scenario 'when does not user has any request_template permissions except manage list' do
        visit request_templates_path

        expect(page).not_to have_content('Released')
        expect(page).not_to have_content('View')
      end

      scenario 'when user has "Update Request Templates State" permission user can see links' do
        permissions << inspect_request_templates_permission
        visit request_templates_path

        expect(page).to have_content('Released')
        expect(page).to have_content('View')
      end
    end

    context '"Update Request Templates State" links' do
      background do
        permissions << list_request_templates_permission
        permissions << inspect_request_templates_permission
      end

      scenario 'when does not user has any request_template permissions except manage list' do
        visit request_templates_path

        expect(page).not_to have_content('>>')
        expect(page).not_to have_content('<<')
      end

      scenario 'when user has "Update Request Templates State" permission user can see links' do
        permissions << update_state_request_template_permission
        visit request_templates_path

        expect(page).to have_content('>>')
        expect(page).to have_content('<<')
        expect(page).to have_content('Released')

        click_on '>>'
        expect(page).to have_content('Retired')
      end
    end

    context '"Unarchive" links' do
      background do
        permissions << list_request_templates_permission
        permissions << inspect_request_templates_permission
        permissions << update_state_request_template_permission
        request_template.archive
      end

      scenario 'when user has "Update Request Templates State" permission user can see links' do
        visit request_templates_path

        click_on 'Unarchive'

        expect(page).not_to have_no_access_message
        expect(page).not_to have_content('Archived')
      end
    end

    context '"Delete" link' do
      background do
        permissions << list_request_templates_permission
        permissions << inspect_request_templates_permission
        request_template.archive
      end

      scenario 'when does not user has any request_template permissions except manage list' do
        visit request_templates_path
        expect(page).not_to have_css('.delete_request_template')
      end

      scenario 'when user has "Delete Request Template" permission user can see "Delete" link' do
        permissions << delete_request_template_permission
        visit request_templates_path

        expect(page).to have_css('.delete_request_template')
        page.find("#request_template_#{ request_template.id } .delete_request_template").click
        expect(page).to have_content(I18n.t('activerecord.notices.deleted', model: I18n.t('activerecord.models.request_template')))
      end
    end
  end

  describe 'List by app assignment', js: true do
    given!(:restricted_request) { create(:request_with_app, name: 'Restricted Request') }
    given!(:restricted_request_template) { create(:request_template, request: restricted_request) }

    before do
      permissions << list_request_templates_permission
    end

    scenario 'can see request templates related to user apps' do
      visit request_templates_path
      wait_for_ajax

      expect(page).to have_content request_template.name
      expect(page).not_to have_content restricted_request_template.name
    end

    scenario 'cannot see request templates of inactive team' do
      team.deactivate!
      visit request_templates_path
      wait_for_ajax

      expect(page).not_to have_content request_template.name
    end
  end

  def have_no_access_message
    have_content(I18n.t(:'activerecord.errors.no_access_to_view_page'))
  end

end
