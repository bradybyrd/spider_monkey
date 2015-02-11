
require 'spec_helper'

feature 'Deployment Window Series edit page has status', js: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given!(:deployment_window_series) { create(:deployment_window_series, aasm_state: 'pending') }
  given!(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    permissions << 'Environment' << 'Access Metadata' << 'Edit Deployment Windows Series' <<
                   'View Deployment Windows list' << 'Update Deployment Windows State'
    sign_in user
  end

  scenario 'moves to draft redirect to list page' do
    visit edit_deployment_window_series_path(deployment_window_series)
    expect(page).to have_content('<<Pending>>')
    transition_state_left
    expect(current_path).to eq deployment_window_series_index_path
  end

  def transition_state_left
    page.find(".state_transition_left").click
    wait_for_ajax
    page.find(".state_transition_left").click
    wait_for_ajax
  end
end
