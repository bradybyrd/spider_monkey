require 'spec_helper'

feature "Viewing a Step", js: true do
  given!(:user) { create(:user, :with_role_and_group) }
  given!(:request) { create(:request, :with_assigned_app, user: user) }
  given!(:step) { create(:step, request: request) }
  given!(:phase) { create(:phase) }
  given!(:runtime_phase) { create(:runtime_phase, phase: phase) }

  background do
    step.update_attributes(phase_id: phase.id, runtime_phase_id: runtime_phase.id)
  end

  context "with phases" do
    scenario "cannot be edited without edit step permission" do
      sign_in_as_user

      visit request_path(request)
      view_step step.name

      expect(modal_dialog).to have_text(phase.name)
      expect(modal_dialog).to have_text(runtime_phase.name)
      expect(modal_dialog).not_to have_select('step_runtime_phase_id')
      expect(modal_dialog).not_to have_select('step_phase_id')
    end

    scenario "can be edited by root group user" do
      sign_in create(:user, :root)

      visit request_path(request)
      view_step step.name

      expect(modal_dialog).to have_text(phase.name)
      expect(modal_dialog).to have_text(runtime_phase.name)
      expect(modal_dialog).to have_select('step_runtime_phase_id')
      expect(modal_dialog).to have_select('step_phase_id')
    end
  end

  def view_step(step_name)
    find(".step_name", text: step_name).click
  end

  def modal_dialog
    find("#facebox")
  end

  def sign_in_as_user
    permissions = TestPermissionGranter.new(user.groups.first.roles.first.permissions)
    permissions << some_permissions
    sign_in user
  end

  def some_permissions
    [
      'Requests', 'View Requests list', 'Inspect Request',
      'Create Requests', 'Modify Requests Details', 'Inspect Steps',
      'Add New Step', 'View created Requests list', 'View General tab'
    ]
  end
end