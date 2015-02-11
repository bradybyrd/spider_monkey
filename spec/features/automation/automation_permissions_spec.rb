require 'spec_helper'

feature 'Automation page permissions', custom_roles: true, js: true do
  given!(:user)   { create(:user, :non_root, :with_role_and_group, login: 'Jupiter') }
  given!(:permissions) { user.groups.first.roles.first.permissions }
  given!(:permissions_list) { PermissionsList.new }
  given!(:basic_permissions) { [
      create(:permission, permissions_list.permission('Dashboard')),
      create(:permission, permissions_list.permission('Environment')),
      create(:permission, permissions_list.permission('Access Metadata'))
  ] }
  given!(:view_automation_list) { create(:permission, permissions_list.permission('View Automation list')) }
  given!(:manage_automation) { [
      create(:permission, permissions_list.permission('Create Automation')),
      create(:permission, permissions_list.permission('Edit Automation')),
      create(:permission, permissions_list.permission('Test Automation')),
      create(:permission, permissions_list.permission('Import Scripts from Library')),
      create(:permission, permissions_list.permission('Update Automation State')),
      create(:permission, permissions_list.permission('Delete Automation'))
  ] }

  background do
    permissions << basic_permissions

    sign_in(user)
  end

  context 'automation scripts index page' do
    given(:released_script) { create(:general_script, name: 'Script1', aasm_state: 'released') }
    given(:archived_script) { create(:general_script, name: 'Script2', archived_at: Time.current, archive_number: '1', aasm_state: 'archived_state') }
    given!(:scripts) { [released_script, archived_script] }
    before { GlobalSettings.stub(:automation_enabled?).and_return(true) }

    context 'automation scripts' do
      scenario 'when user does not have any automation permissions' do
        visit manage_metadata_path

        expect(page).not_to have_link('Automation') # Tab
        expect(page).not_to have_link('BMC BladeLogic') # Tab
      end

      scenario 'when user has "list automation" permission user can view automation list' do
        permissions << view_automation_list
        visit automation_scripts_path

        # Tab
        expect(page).to have_link('Automation')

        # List
        expect(page).to have_css('table#scripts_list')
        expect(page).to have_content('Script1')

        # Actions
        expect(page).not_to have_link('Script1') # Script name is a text
        expect(page).not_to have_link('Edit')
        expect(page).not_to have_link('Delete')
        expect(page).not_to have_link('Unarchive')
        expect(page).not_to have_link('Test')
        expect(page).not_to have_link('Create_automation')
        expect(page).not_to have_link('Import scripts from Library')
        expect(page).not_to have_link('<<')
        expect(page).not_to have_link('>>')
      end

      scenario 'when user has "manage automation" permissions user can manage automation list' do
        permissions << view_automation_list
        permissions << manage_automation
        visit automation_scripts_path

        # Actions
        expect(page).to have_link('Script1') # Script name is a link too
        expect(page).to have_link('Edit')
        expect(page).to have_link('Delete')
        expect(page).to have_link('Unarchive')
        expect(page).to have_link('Test')
        expect(page).to have_link('Create_automation')
        expect(page).to have_link('Import scripts from Library')
        expect(page).to have_link('<<')
        expect(page).to have_link('>>')
      end

      scenario 'when user has "manage automation" permissions user can change state of automation script' do
        permissions << view_automation_list
        permissions << manage_automation
        visit automation_scripts_path

        move_state_right(released_script)
        expect(page).to have_state(released_script, 'Retired')

        click_on 'Unarchive'
        expect(page).to have_state(archived_script, 'Retired')
      end

    end

    context 'BMC BladeLogic scripts' do
      given!(:bladelogic_script) { create(:bladelogic_script, name: 'BladeLogic Script1') }
      before { GlobalSettings.stub(:bladelogic_enabled?).and_return(true) }

      scenario 'when does not user has any automation permissions' do
        visit manage_metadata_path

        expect(page).not_to have_link('BMC BladeLogic') # Tab
      end

      scenario 'when user has "list automation" permission user can view BladeLogic automation list' do
        permissions << view_automation_list
        visit bladelogic_path

        # Tab
        expect(page).to have_link('BMC BladeLogic')

        # List
        expect(page).to have_css('table#scripts_list')
        expect(page).to have_content('BladeLogic Script1')

        # Actions
        expect(page).not_to have_link('BladeLogic Script1') # Script name is a text
        expect(page).not_to have_link('edit')
        expect(page).not_to have_link('delete')
        expect(page).not_to have_link('test')
        expect(page).not_to have_link('Create_automation')
        expect(page).not_to have_link('Import from Library')
      end

      scenario 'when user has "manage automation" permissions user can manage BladeLogic automation list' do
        permissions << view_automation_list
        permissions << manage_automation
        visit bladelogic_path

        # Actions
        expect(page).to have_link('BladeLogic Script1') # Script name is a link too
        expect(page).to have_link('edit')
        expect(page).to have_link('delete')
        expect(page).to have_link('test')
        expect(page).to have_link('Create_automation')
        expect(page).to have_link('Import from Library')
      end

    end
  end

  def move_state_right(automation_script)
    within "#state_list_#{ automation_script.id }" do
      click_on '>>'
    end
  end

  def have_state(automation_script, state)
    have_css("#td_state_#{ automation_script.id }", text: state)
  end

  def have_archived_state(automation_script)
    have_content(automation_script.name + ' [archived')
  end
end
