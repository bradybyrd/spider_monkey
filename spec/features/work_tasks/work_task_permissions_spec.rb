require 'spec_helper'

feature 'User on a work_task page', custom_roles: true, js: true do
  given!(:user)             { create(:user, :non_root, :with_role_and_group, login: 'Doom') }
  given!(:work_task)        { create(:work_task, name: 'Bat Rider') }
  given!(:permissions)      { user.groups.first.roles.first.permissions }
  given!(:permissions_list) { PermissionsList.new }
  given(:permission_to) do
    {
        work_task: {
            list:              create(:permission, permissions_list.permission('View Work Tasks list')),
            create:            create(:permission, permissions_list.permission('Create Work Tasks')),
            edit:              create(:permission, permissions_list.permission('Edit Work Tasks')),
            archive_unarchive: create(:permission, permissions_list.permission('Archive/Unarchive Work Tasks')),
            delete:            create(:permission, permissions_list.permission('Delete Work Tasks'))
        }
    }
  end

  background { sign_in(user) }

  context 'with the appropriate permissions' do

    scenario 'sees the list of the work_tasks' do
      visit work_tasks_path

      expect(page).not_to have_content(work_task.name)
      permissions << permission_to[:work_task][:list]

      visit work_tasks_path

      expect(page).to have_css('form#reorder_work_tasks > table')
      expect(page).to have_content(work_task.name)
    end

    scenario 'creates a new work_task' do
      work_task_name    = 'Juliet'
      permissions       << permission_to[:work_task][:list]

      visit work_tasks_path

      expect(page).not_to have_button I18n.t(:'work_task.buttons.add_new')
      permissions       << permission_to[:work_task][:create]

      visit work_tasks_path

      click_on I18n.t(:'work_task.buttons.add_new')
      fill_in :work_task_name, with: work_task_name
      click_on I18n.t(:create)
      wait_for_ajax

      expect(page).to have_content work_task_created_message
      expect(page).to have_content work_task_name
    end

    scenario 'edits the work_task' do
      work_task_new_name  = 'Sakura'
      permissions           << permission_to[:work_task][:list]

      visit work_tasks_path

      expect(page).not_to have_link I18n.t(:edit)
      expect(page).not_to have_link work_task.name
      permissions           << permission_to[:work_task][:edit]

      visit work_tasks_path

      click_on I18n.t(:edit)
      fill_in :work_task_name, with: work_task_new_name
      click_on I18n.t(:update)
      wait_for_ajax

      expect(page).to have_content work_task_updated_message
      expect(page).to have_link work_task_new_name
    end

    scenario 'archives and unarchives a work_task' do
      permissions << permission_to[:work_task][:list]

      visit work_tasks_path

      expect(page).not_to have_link I18n.t(:archive)
      permissions << permission_to[:work_task][:archive_unarchive]

      visit work_tasks_path

      click_on I18n.t(:archive)
      wait_for_ajax

      expect(work_task.reload).to be_archived
      click_on I18n.t(:unarchive)
      wait_for_ajax

      expect(page).to have_link I18n.t(:archive)
      expect(current_path).to eq work_tasks_path
      expect(work_task.reload).not_to be_archived
    end

    scenario 'deletes an archived work_task' do
      work_task.archive
      permissions << permission_to[:work_task][:list]

      visit work_tasks_path

      expect(page).not_to have_link(I18n.t(:delete))
      permissions << permission_to[:work_task][:delete]

      visit work_tasks_path

      expect(page).to have_link(I18n.t(:delete))

      click_on I18n.t(:delete)

      expect(page).to have_content work_task_deleted_message
      expect(page).not_to have_content work_task.name
      expect(current_path).to eq work_tasks_path
    end

  end
end


def work_task_created_message
  I18n.t(:'activerecord.notices.created', model: I18n.t(:'activerecord.models.work_task'))
end

def work_task_updated_message
  I18n.t(:'activerecord.notices.updated', model: I18n.t(:'activerecord.models.work_task'))
end

def work_task_deleted_message
  I18n.t(:'activerecord.notices.deleted', model: I18n.t(:'activerecord.models.work_task'))
end