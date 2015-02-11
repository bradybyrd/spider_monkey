require 'spec_helper'

feature 'Deployment Window Series page has status' do
  given!(:user) { create(:user, :root) }
  given!(:deployment_window_series) { create(:deployment_window_series, aasm_state: 'draft') }

  background do
    sign_in user
  end

  scenario 'changing states on list page', js: true do
    visit deployment_window_series_index_path
    expect(page).to have_content(deployment_window_series.name)
    expect(page).to have_state('Draft')

    move_state_right(deployment_window_series)
    expect(page).to have_state('Pending')

    move_state_right(deployment_window_series)
    expect(page).to have_state('Released')

    move_state_right(deployment_window_series)
    expect(page).to have_state('Retired')

    move_state_right(deployment_window_series)
    expect(page).to have_archived_state(deployment_window_series)

    click_on 'Unarchive'
    expect(page).to have_state('Retired')
  end

  scenario 'expired series can only be archived, then deleted' do
    expire_series
    visit deployment_window_series_index_path
    expect(page).to have_state('Draft')

    click_on 'Archive'
    expect(page).to have_archived_state(deployment_window_series)
    expect(page).not_to have_content('Unarchive')

    click_on 'Delete'
    expect(page).not_to have_archived_state(deployment_window_series)
  end

  scenario 'cannot edit archived series' do
    expire_series
    visit deployment_window_series_index_path
    expect(page).to have_state('Draft')

    click_on 'Archive'
    expect(page).to have_archived_state(deployment_window_series)

    visit edit_deployment_window_series_path(deployment_window_series)
    click_on 'Update'
    expect(page).to have_content('You cannot update an archived Deployment Window')
  end

  def move_state_right(series)
    within "#state_list_#{ series.id }" do
      click_on '>>'
    end
  end

  def have_state(state)
    have_css("#td_state_#{ deployment_window_series.id }", text: state)
  end

  def have_archived_state(series)
    have_content(series.name + ' [archived')
  end

  def expire_series
    deployment_window_series.start_at = Time.zone.now - 2.day
    deployment_window_series.finish_at = Time.zone.now - 1.days
    deployment_window_series.save validate: false
  end

end
