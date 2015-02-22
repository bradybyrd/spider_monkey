require 'spec_helper'

feature 'Procedures page permissions', custom_roles: true do
  given!(:user) { create(:old_user, :not_admin_with_role_and_group) }
  given!(:procedure) { create(:procedure) }
  given!(:basic_permissions) { [ 'View My Applications', 'Environment', 'Access Metadata' ] }

  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    permissions << basic_permissions
    sign_in user
  end

  describe 'procedure index page' do
    context 'procedure list' do
      scenario 'when user does not have any procedure permissions' do
        visit procedures_path

        expect(page).not_to have_css('#procedures')
        expect(page).not_to have_content(procedure.name)
      end

      scenario 'when user has "list procedures" permission user can view procedures list' do
        permissions << 'View Procedures list'
        visit procedures_path

        expect(page).to have_css('#procedures')
        expect(page).to have_content(procedure.name)
      end

      context 'user without edit permission' do
        scenario 'user is not able to click on edit active procedure' do
          permissions << 'View Procedures list'

          visit procedures_path

          expect(page).not_to have_edit_procedure_link(procedure)
        end

        scenario 'user is not able to click on edit archived procedure' do
          archived_procedure = create :procedure, :archived
          permissions << 'View Procedures list'

          visit procedures_path

          expect(page).not_to have_edit_procedure_link(archived_procedure)
        end
      end
    end

    context '"Create Procedure" button' do
      background do
        permissions << 'View Procedures list'
      end

      scenario 'when user does not have any procedure permissions except view list' do
        visit procedures_path
        expect(page).not_to have_css('.create_procedure')

        visit new_procedure_path
        expect(page).not_to have_content('Create Procedure')
      end

      scenario 'when user has "create procedure" permission user can see "Create procedure" button' do
        permissions << 'Create Procedures'
        visit procedures_path

        expect(page).to have_css('.create_procedure')
        page.find('.create_procedure').click
        expect(page).not_to have_no_access_message
      end
    end

    context '"Edit Procedure" link' do
      background do
        permissions << 'View Procedures list'
      end

      scenario 'when user does not have any procedure permissions except view list' do
        visit procedures_path
        expect(page).not_to have_css('.edit_procedure')

        visit edit_procedure_path(procedure)
        expect(page).not_to have_content(procedure.name)
      end

      scenario 'when user has "edit procedure" permission user can see "Edit" link' do
        permissions << 'Edit Procedures'
        visit procedures_path

        expect(page).to have_css('.edit_procedure')
        page.find("#procedure_#{ procedure.id } .edit_procedure").click
        expect(page).to have_content(procedure.name)
      end
    end

    describe '"Update State Procedures" link', js: true do
      background do
        permissions << 'View Procedures list'
      end

      scenario 'when user does not have any procedure permissions except view list' do
        visit procedures_path

        expect(page).not_to have_move_state_right_control
        expect(page).not_to have_move_state_left_control
      end

      scenario 'when user has "Update State Procedure" permission user can see change state links' do
        permissions << 'Update Procedures State'
        visit procedures_path

        expect(page).to have_move_state_right_control
        expect(page).to have_move_state_left_control
        within state_td do
          expect(page).to have_content('Released')
        end


        move_state_right

        within state_td do
          expect(page).to have_content('Retired')
        end
      end
    end

    context '"Delete" link' do
      background do
        permissions << 'View Procedures list'
        procedure.archive
      end

      scenario 'when user does not have any procedure permissions except view list' do
        visit procedures_path
        expect(page).not_to have_css('.delete_procedure')
      end

      scenario 'when user has "Delete Procedure" permission user can see "Delete" link' do
        permissions << 'Delete Procedures'
        visit procedures_path

        expect(page).to have_css('.delete_procedure')
        page.find("#procedure_#{ procedure.id } .delete_procedure").click
        expect(page).to have_content('Procedure was successfully deleted')
      end
    end
  end

  describe 'procedure steps', js: true do
    background do
      permissions << 'Edit Procedures'
    end

    given!(:step) { create :step, procedure_id: procedure.id, request_id: nil }

    context 'add new step' do
      scenario 'has access' do
        permissions << 'Add New Step'
        visit edit_procedure_path(procedure)

        expect(page).to have_new_step_link
      end

      scenario 'no access' do
        visit edit_procedure_path(procedure)

        expect(page).to_not have_new_step_link
      end
    end

    context 'step tabs permissions' do
      scenario 'has access' do
        permissions << 'View General tab'
        permissions << 'View Automation tab'
        permissions << 'Add New Step'

        visit edit_procedure_path(procedure)
        click_new_step
        wait_for_ajax

        expect(step_popup).to have_general_tab
        expect(step_popup).to have_automation_tab
      end

      scenario 'no access' do
        permissions << 'Add New Step'

        visit edit_procedure_path(procedure)
        click_new_step
        wait_for_ajax

        expect(step_popup).to_not have_general_tab
        expect(step_popup).to_not have_automation_tab
      end
    end

    context 'edit step' do
      scenario 'has access' do
        permissions << 'Edit Steps'

        visit edit_procedure_path(procedure)

        expect(steps_list).to have_edit_step_link
      end

      scenario 'no access' do
        visit edit_procedure_path(procedure)

        expect(steps_list).to_not have_edit_step_link
      end
    end

    context 'delete step' do
      scenario 'has access' do
        permissions << 'Delete Steps'

        visit edit_procedure_path(procedure)

        expect(steps_list).to have_delete_step_link
        expect(step_action_links).to have_delete_step_link
      end

      scenario 'no access' do
        visit edit_procedure_path(procedure)

        expect(steps_list).to_not have_delete_step_link
        expect(step_action_links).to_not have_delete_step_link
      end
    end

    context 'turn on/off step' do
      scenario 'has access' do
        permissions << 'Turn On/Off'

        visit edit_procedure_path(procedure)

        expect(steps_list).to have_step_on_link
        expect(step_action_links).to have_turn_on_off_link
      end

      scenario 'no access' do
        visit edit_procedure_path(procedure)

        expect(steps_list).to_not have_step_on_link
        expect(step_action_links).to_not have_turn_on_off_link
      end
    end

    context 'modify assignment' do
      scenario 'has access' do
        permissions << 'Edit Owner'
        permissions << 'Add New Step'

        visit edit_procedure_path(procedure)

        expect(step_action_links).to have_modify_assignment_link

        click_new_step
        wait_for_ajax

        within step_popup do
          expect(step_owner_select).to_not be_disabled
        end
      end

      context 'reorder steps button' do
        scenario 'is available when user has reorder_steps permission' do
          permissions << 'Reorder Steps'

          visit edit_procedure_path(procedure)

          expect(page).to have_reorder_step_button
        end

        scenario 'is unavailable when user does not have reorder_steps permission' do
          visit edit_procedure_path(procedure)

          expect(page).not_to have_reorder_step_button
        end
      end

      scenario 'no access' do
        permissions << 'Add New Step'

        visit edit_procedure_path(procedure)

        expect(step_action_links).to_not have_modify_assignment_link

        click_new_step
        wait_for_ajax

        within step_popup do
          expect(step_owner_select).to be_disabled
        end
      end
    end

    context 'modify component' do
      scenario 'has access' do
        permissions << 'Select Component'
        permissions << 'Add New Step'

        visit edit_procedure_path(procedure)

        expect(step_action_links).to have_modify_component_link

        click_new_step
        wait_for_ajax

        within step_popup do
          expect(step_component_select).not_to be_disabled
        end
      end

      scenario 'no access' do
        permissions << 'Add New Step'

        visit edit_procedure_path(procedure)

        expect(step_action_links).to_not have_modify_component_link

        click_new_step
        wait_for_ajax

        within step_popup do
          expect(step_component_select).to be_disabled
        end
      end
    end

    context 'modify task/phase' do
      scenario 'has access' do
        permissions << 'Edit Task/Phase'
        permissions << 'Add New Step'
        permissions << 'View General tab'

        visit edit_procedure_path(procedure)

        expect(step_action_links).to have_modify_task_phase_link

        click_new_step
        wait_for_ajax

        within step_popup do
          expect(step_phase_select).not_to be_disabled
          expect(step_runtime_phase_select).not_to be_disabled
          expect(step_work_task_select).not_to be_disabled
        end
      end

      scenario 'no access' do
        permissions << 'Add New Step'
        permissions << 'View General tab'

        visit edit_procedure_path(procedure)

        expect(step_action_links).to_not have_modify_task_phase_link

        click_new_step
        wait_for_ajax

        within step_popup do
          expect(step_phase_select).to be_disabled
          expect(step_runtime_phase_select).to be_disabled
          expect(step_work_task_select).to be_disabled
        end
      end
    end
  end

  describe 'create procedure' do
    scenario 'when user has permissions for edit procedure user is being redirected to edit procedure' do
      permissions << 'Create Procedures' << 'Edit Procedures'
      create :app

      visit new_procedure_path
      fill_in_all_fields
      click_on 'Create'

      expect(page.current_path).to eq edit_procedure_path(just_created_procedure)
    end

    scenario 'when user does not have permissions for edit procedure user is being redirected to procedures list' do
      permissions << 'Create Procedures'
      create :app

      visit new_procedure_path
      fill_in_all_fields
      click_on 'Create'

      expect(page.current_path).to eq procedures_path
    end
  end

  describe 'new procedure' do
    scenario 'when procedure is archived user is not able to edit steps' do
      visit logout_path
      admin = create :user, :root
      sign_in admin
      archived_procedure = create :procedure, :with_steps, :archived

      visit edit_procedure_path(archived_procedure)

      expect(page).to have_steps_section
      expect(page).not_to have_edit_link
      expect(page).not_to have_delete_link
      expect(page).not_to have_change_step_status_link
      expect(page).not_to have_new_step_link
    end

    def have_steps_section
      have_css('table#steps_list tr', minimum: 2)
    end

    def have_edit_link
      have_css('tr.step a.step_editable_link', minimum: 1)
    end

    def have_delete_link
      have_css('tr.step a[title="Delete"]', minimum: 1)
    end

    def have_change_step_status_link
      have_css('tr.step a.ON', minimum: 1)
    end

    def have_new_step_link
      have_link('New Step')
    end
  end

  describe 'procedure EDIT page' do
    scenario 'New Step popup', js: true do
      permissions << 'Edit Procedures'
      permissions << 'Add New Step'
      permissions << 'View General tab'
      permissions << 'View Automation tab'
      permissions << 'View Notes tab'
      permissions << 'View Documents tab'
      permissions << 'View Properties tab'
      permissions << 'View Server properties tab'
      permissions << 'View Design tab'

      visit edit_procedure_path(procedure)
      click_on 'New Step'
      wait_for_ajax

      expect(page).to have_css('#st_general')
      expect(page).to have_css('#st_automation')
      expect(page).not_to have_css('#st_notes')
      expect(page).not_to have_css('#st_documents')
      expect(page).not_to have_css('#st_properties')
      expect(page).not_to have_css('#st_server_properties')
      expect(page).not_to have_css('#st_design')
      expect(page).not_to have_css('#st_content')
    end

    scenario 'when there is an archived procedure then user does not see steps edit links' do
      procedure = create :procedure, :archived, :with_steps
      permissions << 'Edit Procedures'
      sign_in_as_admin

      visit edit_procedure_path(procedure)

      expect(page).not_to have_all_link
      expect(page).not_to have_none_link
      expect(page).not_to have_on_link
      expect(page).not_to have_off_link
      expect(page).not_to have_bulk_delete_step_link
      expect(page).not_to have_modify_assignment_link
      expect(page).not_to have_modify_component_link
      expect(page).not_to have_modify_task_phase_link
      expect(page).not_to have_turn_on_off_link
      expect(page).not_to have_step_checkboxes
    end
  end

  private

  def sign_in_as_admin
    visit logout_path
    admin = create :user, :root
    sign_in admin
  end

  def have_step_checkboxes
    have_css 'table.formatted_steps_table td.step_position input[type="checkbox"]'
  end

  def have_all_link
    have_link 'All'
  end

  def have_none_link
    have_link 'None'
  end

  def have_on_link
    have_link 'On'
  end

  def have_off_link
    have_link 'Off'
  end

  def have_no_access_message
    have_content(I18n.t(:'activerecord.errors.no_access_to_view_page'))
  end

  def have_move_state_right_control
    have_content('>>')
  end

  def have_move_state_left_control
    have_content('<<')
  end

  def move_state_right
    within "#state_list_#{ procedure.id }" do
      click_on '>>'
    end
  end

  def state_td
    "#td_state_#{ procedure.id }"
  end

  def click_new_step
    click_link "New Step"
  end

  def have_new_step_link
    have_link 'New Step'
  end

  def have_general_tab
    have_css 'li#st_general'
  end

  def have_automation_tab
    have_css 'li#st_automation'
  end

  def have_edit_step_link
    have_link 'Edit'
  end

  def have_delete_step_link
    have_link 'Delete'
  end

  def have_bulk_delete_step_link
    have_css '.step_header_wrapper a', text: 'Delete'
  end

  def have_step_on_link
    have_link 'ON'
  end

  def have_turn_on_off_link
    have_link 'Turn On/Off'
  end

  def have_modify_assignment_link
    have_link 'Modify Assignment'
  end

  def have_modify_component_link
    have_link 'Modify Component'
  end

  def have_modify_task_phase_link
    have_link 'Modify Task/Phase'
  end

  def step_owner_select
    find_by_id 'step_owner_id'
  end

  def step_component_select
    find_by_id 'step_component_id'
  end

  def step_phase_select
    find_by_id 'step_phase_id'
  end

  def step_runtime_phase_select
    find_by_id 'step_runtime_phase_id'
  end

  def step_work_task_select
    find_by_id 'step_work_task_id'
  end

  def steps_list
    find_by_id 'steps_list'
  end

  def step_popup
    find_by_id 'facebox'
  end

  def step_action_links
    find_by_id 'step_action_links'
  end

  def have_edit_procedure_link(procedure)
    have_css("a[href='#{edit_procedure_path(procedure)}']")
  end

  def just_created_procedure
    Procedure.last
  end

  def fill_in_all_fields
    within '#new_procedure_template' do
      fill_in 'Name', with: "Procedure #{Time.now.to_s(:number)}"
      select App.active.first.name, from: "procedure[app_ids][]"
    end
  end

  def have_reorder_step_button
    have_css('a#reorder_steps')
  end
end
