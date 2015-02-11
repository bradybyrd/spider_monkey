require 'spec_helper'

feature 'User on a settings page', custom_roles: true, js: true do
  given!(:user)                   { create(:user, :non_root, :with_role_and_group, login: 'Storm Spirit') }
  given!(:permissions)            { user.groups.first.roles.first.permissions }
  given!(:permissions_list)       { PermissionsList.new }
  given!(:permission_to) do
    {
        settings: {
            general: {
                access:     create(:permission, permissions_list.permission('Access Settings')),
                view:       create(:permission, permissions_list.permission('View General')),
                edit:       create(:permission, permissions_list.permission('Edit General Settings'))
            },

            calendar_preferences: {
                manage_calendar_preferences:
                            create(:permission, permissions_list.permission('View Calendar Preferences/Manage'))
            },
            statistic: {
                view:       create(:permission, permissions_list.permission('View Statistics'))
            },
            automation_monitor: {
                view:       create(:permission, permissions_list.permission('View Automation Monitor')),
                clear:      create(:permission, permissions_list.permission('Clear Job Queue'))

            },
            notification_template: {
                list:       create(:permission, permissions_list.permission('View Notification Templates')),
                create:     create(:permission, permissions_list.permission('Create Notification Template')),
                show:       create(:permission, permissions_list.permission('Show Notification Template')),
                edit:       create(:permission, permissions_list.permission('Edit Notification Template')),
                delete:     create(:permission, permissions_list.permission('Delete Notification Temp'))
            }
        },

        general: {
            dashboard: create(:permission, permissions_list.permission('Dashboard'))
        }
    }
  end

  background do
    permissions << permission_to[:general][:dashboard]
    sign_in(user)
  end

  context 'clicking on settings without the general settings permission' do
    scenario 'sees the calendar preferences tab' do
      permissions << permission_to[:settings][:calendar_preferences][:manage_calendar_preferences]

      visit settings_path

      expect(current_path).to eq calendar_preferences_path
    end
  end

  context 'with the appropriate permissions' do
    describe 'on a General tab' do
      scenario 'sees the content' do
        visit settings_path

        expect(page).not_to have_link I18n.t(:'tabs.general')
        expect(page).not_to have_settings_form
        permissions << permission_to[:settings][:general][:view]

        visit settings_path

        expect(page).to have_link I18n.t(:'tabs.general')
      end

      scenario 'edits the settings' do
        permissions       << permission_to[:settings][:general][:view]

        visit settings_path

        expect(page).not_to have_button I18n.t(:save)
        permissions       << permission_to[:settings][:general][:edit]

        visit settings_path

        fill_in :GlobalSettings_company_name, with: 'Who Cares inc'
        click_on I18n.t(:save)

        expect(page).to have_content settings_updated_message
      end
    end

    describe 'on a Calendar Preferences tab' do
      scenario 'manages the calendar preferences' do
        pending 'randomly failing spec. fix after code hardening'
        visit calendar_preferences_path

        expect(page).not_to have_link I18n.t(:'tabs.calendar_preferences')
        expect(page).to have_content no_access_message
        expect(current_path).not_to eq calendar_preferences_path
        permissions << permission_to[:settings][:calendar_preferences][:manage_calendar_preferences]

        visit calendar_preferences_path
        check 'Plan'
        wait_for_ajax

        expect(page).to have_content settings_updated_message
        expect(page).to have_link I18n.t(:'tabs.calendar_preferences')
      end
    end

    describe 'on a Statistics tab' do
      scenario 'sees the content' do
        visit statistics_path

        expect(page).not_to have_link I18n.t(:'tabs.statistic')
        expect(page).to have_content no_access_message
        expect(current_path).not_to eq statistics_path
        permissions << permission_to[:settings][:statistic][:view]

        visit statistics_path

        expect(page).to have_link I18n.t(:'tabs.statistic')
        expect(page).to have_css 'table#Statistics'
      end
    end

    describe 'on a Automation Monitor tab' do
      scenario 'sees the content' do
        visit automation_monitor_path

        expect(page).not_to have_link I18n.t(:'tabs.automation_monitor')
        expect(page).to have_content no_access_message
        expect(current_path).not_to eq automation_monitor_path
        permissions << permission_to[:settings][:automation_monitor][:view]

        visit automation_monitor_path

        expect(page).to have_link I18n.t(:'tabs.automation_monitor')
        expect(page).to have_content 'Current Jobs in Queue'
      end

      scenario 'clear the queue job' do
        AutomationQueueData.stub(:clear_queue!).and_return true

        visit automation_monitor_path

        expect(page).not_to have_link I18n.t(:clear_job_queue)
        permissions << permission_to[:settings][:automation_monitor][:view]
        permissions << permission_to[:settings][:automation_monitor][:clear]

        visit automation_monitor_path

        click_on I18n.t(:clear_job_queue)

        expect(page).not_to have_content 'You do not have access'
      end
    end

    describe 'on a Notification Template tab' do
      given!(:notification_template)  { create(:notification_template, title: 'Lycan') }

      scenario 'sees the content' do
        visit notification_templates_path

        expect(page).not_to have_link I18n.t(:'tabs.notification_template')
        expect(page).to have_content no_access_message
        expect(current_path).not_to eq notification_templates_path
        permissions << permission_to[:settings][:notification_template][:list]

        visit notification_templates_path

        expect(page).to have_link I18n.t(:'tabs.notification_template')
        expect(page).to have_content I18n.t(:'notification_template.titles.notification_templates')
        expect(page).to have_content notification_template.title
      end

      scenario 'creates new item' do
        notification_template_title = 'Ooo u oo in the army now!'
        permissions << permission_to[:settings][:notification_template][:list]

        visit notification_templates_path

        expect(page).not_to have_link I18n.t(:'notification_template.buttons.create')
        permissions << permission_to[:settings][:notification_template][:create]

        visit notification_templates_path

        click_on I18n.t(:'notification_template.buttons.create')
        expect(current_path).to eq new_notification_template_path

        fill_in :notification_template_title, with: notification_template_title
        fill_in :notification_template_body, with: 'Hello Mr or Mrs. We are delighted you are with us. Regards'
        click_on I18n.t(:create)
        wait_for_ajax

        expect(page).to have_content notification_template_created_message
        expect(current_path).to eq root_path # after create one is redirected to #show, but as no permissions -> to dashboard instead
      end

      scenario 'edits the item' do
        new_notification_template_title = 'Skydiving rules!'
        permissions << permission_to[:settings][:notification_template][:list]

        visit notification_templates_path

        expect(page).not_to have_link I18n.t(:edit)
        permissions << permission_to[:settings][:notification_template][:edit]

        visit notification_templates_path

        click_on I18n.t(:edit)
        expect(current_path).to eq edit_notification_template_path(notification_template)

        fill_in :notification_template_title, with: new_notification_template_title
        click_on I18n.t(:update)
        wait_for_ajax

        expect(page).to have_content notification_template_updated_message
        expect(current_path).to eq root_path # after update one is redirected to #show, but as no permissions -> to dashboard instead
      end

      scenario 'shows the item' do
        permissions << permission_to[:settings][:notification_template][:list]

        visit notification_templates_path

        expect(page).not_to have_link I18n.t(:show)
        expect(page).not_to have_link notification_template.title
        permissions << permission_to[:settings][:notification_template][:show]

        visit notification_templates_path

        click_on notification_template.title

        expect(current_path).to eq notification_template_path(notification_template)
      end

      scenario 'deletes the item' do
        permissions << permission_to[:settings][:notification_template][:list]

        visit notification_templates_path

        expect(page).not_to have_link I18n.t(:delete)
        permissions << permission_to[:settings][:notification_template][:delete]

        visit notification_templates_path

        click_on I18n.t(:delete)

        expect(page).to have_content notification_template_deleted_message
        expect(current_path).to eq notification_templates_path
      end
    end

  end
end


def no_access_message
  I18n.t(:'activerecord.errors.no_access_to_view_page')
end

def settings_updated_message
  I18n.t(:'settings.updated')
end

def work_task_deleted_message
  I18n.t(:'activerecord.notices.deleted', model: I18n.t(:'activerecord.models.settings'))
end

def notification_template_created_message
  I18n.t(:'notification_template.notices.created')
end

def notification_template_updated_message
  I18n.t(:'notification_template.notices.updated')
end

def notification_template_deleted_message
  I18n.t(:'notification_template.notices.deleted')
end

def have_settings_form
  have_css 'form.settingsform'
end
