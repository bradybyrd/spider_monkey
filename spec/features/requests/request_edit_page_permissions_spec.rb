require 'spec_helper'

feature 'User on a edit request page', custom_roles: true, js: true do
  given!(:user)             { create(:user, :non_root, :with_role_and_group, login: 'Mr. Who') }
  given!(:request)          { create(:request, :with_assigned_app, user: user) }
  given!(:permissions)      { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  context 'being a root user' do
    scenario 'can create request template when has no assigned apps' do
      sign_in create(:user, :root)
      visit edit_request_path(request)

      expect(page).to have_button create_request_template_button
      click_on create_request_template_button
      click_on save_request_template_button
      wait_for_ajax

      expect(page).to have_content template_created_message
    end
  end

  context 'being a non root user' do
    background do
      permissions << 'Inspect Request' << 'Inspect Steps' << 'View created Requests list'
      sign_in(user)
    end

    context 'in step section header without the appropriate permissions' do
      scenario 'does not see "Reorder Steps", "Apply Template" and "Add Procedure" buttons' do
        visit edit_request_path(request)

        expect(page).not_to have_custom_button('Reorder Steps')
        expect(page).not_to have_custom_button('Apply Template')
        expect(page).not_to have_custom_button('Add Procedure')
      end
    end

    context 'with the appropriate permissions' do
      context 'in step section header' do
        scenario 'sees "Reorder Steps" button' do
          permissions << 'Reorder Steps'
          visit edit_request_path(request)

          expect(page).to have_custom_button('Reorder Steps')
        end

        scenario 'sees "Apply Template" button' do
          permissions << 'Apply Template'
          visit edit_request_path(request)

          expect(page).to have_custom_button('Apply Template')
        end

        scenario 'sees "Add Procedure" button' do
          permissions << 'Add Procedure'
          visit edit_request_path(request)

          expect(page).to have_custom_button('Add Procedure')
        end

        scenario 'can see "Start Automatically?" check box' do
          permissions << 'Modify Requests Details' << 'Start Automatically'

          visit edit_request_path(request)
          click_link I18n.t(:expand)
          click_link I18n.t('request.modify_details')

          expect(request_details).to have_auto_start_check_box
        end
      end

      context 'regardless permissions' do
        scenario 'cannot see "Start Automatically?" check box' do
          permissions << 'Modify Requests Details'

          visit edit_request_path(request)
          click_link I18n.t(:expand)
          click_link I18n.t('request.modify_details')

          expect(request_details).not_to have_auto_start_check_box
        end
      end

      context 'in step section' do
        scenario 'sees the New Step link' do
          visit edit_request_path(request)

          expect(page).not_to have_link I18n.t(:'step.buttons.new')
          expect(current_path).to eq edit_request_path(request)

          permissions << 'Add New Step'

          visit edit_request_path(request)
          wait_for_ajax

          expect(page).to have_link I18n.t(:'step.buttons.new')
        end

        scenario 'sees steps list' do
          permissions << 'Inspect Request'
          step = create(:step)
          request.steps = [step]

          visit edit_request_path(request)
          wait_for_ajax

          expect(page).to have_steps
        end
      end

      context 'in right side bar section' do
        scenario 'sees the create template button and creates a new request template' do
          visit edit_request_path(request)

          expect(request).to be_is_available_for_current_user
          expect(page).not_to have_button create_request_template_button
          expect(current_path).to eq edit_request_path(request)

          permissions << 'Create Template'

          visit edit_request_path(request)

          expect(page).to have_button create_request_template_button
          click_on create_request_template_button
          click_on save_request_template_button
          wait_for_ajax

          expect(page).to have_content template_created_message
        end

        scenario 'sees the delete request button' do
          visit edit_request_path(request)

          expect(page).not_to have_custom_button('Request Delete')

          permissions << 'Delete Request'
          visit edit_request_path(request)

          expect(page).to have_custom_button('Request Delete')
        end
      end
    end
  end

  def create_request_template_button
    'btn-create-template'
  end

  def save_request_template_button
    'btn-save-template'
  end

  def template_created_message
    I18n.t(:'request_template.notices.created')
  end

  def have_steps
    have_css('#steps_list tr.step')
  end

  def have_custom_button(name)
    have_css '#' + name.downcase.gsub(' ', '_')
  end

  def request_details
    find('.request_details')
  end

  def have_auto_start_check_box
    have_css '#request_auto_start'
  end
end
