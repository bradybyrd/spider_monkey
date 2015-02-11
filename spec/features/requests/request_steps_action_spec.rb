require 'spec_helper'

feature 'User on a request page', custom_roles: true, js: true do
  context 'with appropriate permissions' do
    scenario 'edits the step' do
      user = given_user_with_permission_to('Edit Steps')
      request, step = create_request_with_a_step_assigned_to(user)

      sign_in user
      visit edit_request_path(request)
      wait_for_ajax

      expect(request_steps).to have_link('Edit')
    end

    scenario 'deletes the step' do
      user = given_user_with_permission_to('Delete Steps')
      request, step = create_request_with_a_step_assigned_to(user)

      sign_in user
      visit request_path(request)

      click_on_delete_step_button(request, step)

      expect(request_steps).not_to include_step(step)
    end

    scenario 'turns on, off the step' do
      user = given_user_with_permission_to('Turn On/Off')
      request, step = create_request_with_a_step_assigned_to(user)

      sign_in user
      visit request_path(request)

      toggle_step_button(step)

      expect(request_step(step)).to be_turned_off

      toggle_step_button(step)

      expect(request_step(step)).not_to be_turned_off
    end

    scenario 'resets completed step' do
      user = given_user_with_permission_to('Reset Steps')

      request, step = create_request_with_a_step_assigned_to(user)
      complete_step_and_reopen_request(step)

      sign_in user
      visit request_path(request)

      reset_step(step)
      expect(step_state(step)).to be_locked
    end

    scenario 'has inspect step action' do
      user = given_user_with_permission_to('View created Requests list')
      request, step = create_request_with_a_step_assigned_to(user)

      sign_in user
      visit edit_request_path(request)
      wait_for_ajax

      expect(request_steps).to have_link('Edit')
    end
  end

  def given_user_with_permission_to(permission)
    user = create(:user, :non_root, :with_role_and_group)
    permissions = TestPermissionGranter.new(user.groups.first.roles.first.permissions)
    permissions << 'View created Requests list' << 'Inspect Request' << 'Inspect Steps'
    permissions << permission

    user
  end

  def create_request_with_a_step_assigned_to(user)
    request = create(:request, :with_assigned_app, user: user)
    step = create(:step)
    request.steps = [step]

    [request, step]
  end

  def complete_step_and_reopen_request(step)
    step.request.plan_it!
    step.request.start_request!
    step.reload.start!
    step.reload.done!
    step.request.finish!
    step.request.reopen!
  end

  def be_turned_off
    include 'step_off'
  end

  def be_locked
    have_content 'Locked'
  end

  def step_header(step)
    find("#step_#{step.id}_#{step.position}_heading")
  end

  def request_step(step)
    step_header(step)[:class]
  end

  def toggle_step_button(step)
    all("#step_#{step.id}_should_execute").first.click
    wait_for_ajax
  end

  def include_step(step)
    have_content step.name
  end

  def request_steps
    find '#steps_list'
  end

  def click_on_delete_step_button(request, step)
    find(:css, "input#delete-#{request.id}-#{step.id}").click
  end

  def reset_step(step)
    step_header(step).find('.reset_step .button_action').click
    wait_for_ajax
  end

  def step_state(step)
    step_header(step).find('.state_wrapper')
  end
end
