require 'spec_helper'

feature 'Plan templates page permissions', custom_roles: true do
  scenario 'when user has "Edit" permission user can manipulate plan template and stages from show page' do
    user = create(:user, :non_root, :with_role_and_group)
    user_permissions = TestPermissionGranter.new(user.groups.first.roles.first.permissions)
    user_permissions << 'View My Applications' << 'Environment' << 'Access Metadata'
    user_permissions << 'View Plan Templates list' << 'Inspect Plan Templates' << 'Edit Plan Templates'
    plan_template = create(:plan_template, name: 'I will not fail randomly anymore!')
    plan_stage = create(:plan_stage, plan_template: plan_template)

    sign_in user
    visit plan_template_path(plan_template)

    expect(page).to have_stage_link(plan_stage)
    expect(page).to have_edit_plan_template_link
    expect(page).to have_edit_stage_link
    expect(page).to have_delete_stage_link
    expect(page).to have_add_stage_link

    edit_stage_link.click

    expect(page).not_to have_no_access_message
  end

  describe 'Plan Templates pages' do
    given!(:user) { create(:user, :non_root, :with_role_and_group) }
    given!(:plan_template) { create(:plan_template) }
    given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

    background do
      permissions << 'View My Applications' << 'Environment' << 'Access Metadata'

      sign_in user
    end

    context 'Plan Templates list' do
      scenario 'when user does not have any plan_template permissions' do
        pending 'FREEZING!'
        visit plan_templates_path

        expect(page).not_to have_css('#plan_templates')
        expect(page).to have_no_access_message
      end

      scenario 'when user has "View Plan Templates list" permission user can view plan_templates list' do
        permissions << 'View Plan Templates list'
        visit plan_templates_path

        expect(page).to have_css('#plan_templates')
        expect(page).to have_content(plan_template.name)
      end
    end

    context '"Create Plan Templates" button' do
      background do
        permissions << 'View Plan Templates list'
      end

      scenario 'user does not have any plan_template permissions except view list' do
        visit plan_templates_path
        expect(page).not_to have_css('.create_plan_template')

        visit new_plan_template_path
        expect(page).to have_no_access_message
      end

      scenario 'when user has "create plan_template" permission user can see "Create plan_template" button' do
        permissions << 'Create Plan Templates'
        visit plan_templates_path

        expect(page).to have_css('.create_plan_template')
        page.find('.create_plan_template').click
        expect(page).to have_content('Create New Plan Template')
      end
    end

    context '"Inspect Plan Template" link' do
      background do
        permissions << 'View Plan Templates list'
      end

      scenario 'user does not have any plan_template permissions except view list' do
        visit plan_templates_path
        expect(page).not_to have_css('.inspect_plan_template')

        visit plan_template_path(plan_template)
        expect(page).to have_no_access_message
      end

      scenario 'when user has "inspect plan_template" permission user can see plan template link' do
        permissions << 'Inspect Plan Templates'
        visit plan_templates_path

        expect(page).to have_css('.inspect_plan_template')
        page.find("#plan_template_#{ plan_template.id } .inspect_plan_template").click
        expect(page).to have_content(plan_template.name)
      end
    end

    context '"Edit Plan Template" link' do
      background do
        permissions << 'View Plan Templates list' << 'Inspect Plan Templates'
      end

      scenario 'user does not have any plan_template permissions except view list' do
        visit plan_templates_path
        expect(page).not_to have_css('.edit_plan_template')

        visit edit_plan_template_path(plan_template)
        expect(page).to have_no_access_message
      end

      scenario 'when user has "edit plan_template" permission user can see "Edit" link' do
        permissions << 'Edit Plan Templates'
        visit plan_templates_path

        expect(page).to have_css('.edit_plan_template')
        edit_plan_template_link(plan_template).click
        expect(page).not_to have_no_access_message
      end

      scenario 'when user has "Inspect" permission but does not have "Edit" user can not manipulate plan template and stages from show page' do
        permissions << 'Inspect Plan Templates'
        plan_stage = create(:plan_stage, plan_template: plan_template)
        visit plan_template_path(plan_template)

        expect(page).to have_content(plan_stage.name)
        expect(page).not_to have_stage_link(plan_stage)
        expect(page).not_to have_edit_plan_template_link
        expect(page).not_to have_edit_stage_link
        expect(page).not_to have_delete_stage_link
        expect(page).not_to have_add_stage_link
      end
    end

    context 'Update State links for Plan Templates' do
      background do
        permissions << 'View Plan Templates list' << 'Inspect Plan Templates'
      end

      scenario 'user does not have any plan_template permissions except view list' do
        visit plan_templates_path

        expect(page).not_to have_move_state_right_control
        expect(page).not_to have_move_state_left_control
      end

      scenario 'when user has "Update State Plan Templates" permission user can see change status links', js: true do
        permissions << 'Update Plan Templates State'

        visit plan_templates_path

        expect(page).to have_move_state_right_control
        expect(page).to have_move_state_left_control
        within state_td do
          expect(page).to have_content('Released')
        end

        move_state_right_on_list_page

        within state_td do
          expect(page).to have_content('Retired')
        end
      end

      scenario 'when user does not have "Update State Plan Templates" permission user can not update state on details page' do
        visit plan_template_path(plan_template)

        expect(page).not_to have_move_state_right_control
        expect(page).not_to have_move_state_left_control
      end

      scenario 'when user has "Update State Plan Templates" permission user can update state on details page' do
        permissions << 'Update Plan Templates State'

        visit plan_template_path(plan_template)

        expect(page).to have_move_state_right_control
        expect(page).to have_move_state_left_control
        expect(page).to have_content('Released')
        move_state_right
        expect(page).to have_content('Retired')
        move_state_right
        expect(page).to have_content('Archived')
      end
    end

    context '"Delete" link' do
      background do
        permissions << 'View Plan Templates list'
        plan_template.archive
      end

      scenario 'when user does not have any plan_template permissions except view list' do
        visit plan_templates_path
        expect(page).not_to have_css('.delete_plan_template')
      end

      scenario 'when user has "Delete Plan Templates" permission user can see "Delete" link' do
        permissions << 'Delete Plan Templates'
        visit plan_templates_path

        expect(page).to have_css('.delete_plan_template')
        page.find("#plan_template_#{ plan_template.id } .delete_plan_template").click
        expect(page).to have_content('Plan Template was successfully deleted')
      end
    end
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

  def move_state_right_on_list_page
    within "#state_list_#{ plan_template.id }" do
      move_state_right
    end
  end

  def move_state_right
    click_on '>>'
  end

  def state_td
    "#td_state_#{ plan_template.id }"
  end

  def edit_plan_template_link(plan_template)
    page.find("#plan_template_#{ plan_template.id } .edit_plan_template")
  end

  def edit_stage_link
    page.find('.edit_stage')
  end

  def have_stage_link(plan_stage)
    have_css('a', text: plan_stage.name)
  end

  def have_edit_plan_template_link
    have_css('.edit_plan_template')
  end

  def have_edit_stage_link
    have_css('.edit_stage')
  end

  def have_delete_stage_link
    have_css('.delete_stage')
  end

  def have_add_stage_link
    have_css('.add_stage_link')
  end

end
