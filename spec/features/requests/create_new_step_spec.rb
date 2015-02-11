require 'spec_helper'

feature 'Create new request step', js: true do
  scenario 'Click "New step" on request page' do
    user = given_user_with_permissions_to_create_step
    request = create(:request, :with_assigned_app, user: user)

    sign_in user
    visit request_path(request)

    click_link 'New Step'

    expect(page).to have_content('New Step 1')
  end

  private

  def have_new_step_form
    have_css('.step_form')
  end

  def new_step_button
    page.find('a.new_step')
  end

  def given_user_with_permissions_to_create_step
    user = create(:user, :non_root, :with_role_and_group)
    permissions = TestPermissionGranter.new(user.groups.first.roles.first.permissions)
    permissions << 'View created Requests list' << 'Inspect Request' << 'Inspect Steps' << 'Add New Step'

    user
  end
end
