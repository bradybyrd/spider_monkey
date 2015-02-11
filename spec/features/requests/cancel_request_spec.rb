require 'spec_helper'

feature 'Request cancel' do
  given!(:admin) { create(:user) }
  given!(:request) { create(:request_with_app) }

  background do
    request.steps = create_pair(:step)

    sign_in admin
  end

  scenario 'Cancel request from request page' do
    visit request_path(request)

    expect(page).not_to have_cancel_status
    cancel_button.click
    expect(page).to have_cancel_status
  end

  private

  def have_cancel_status
    have_css('#request_status', text: 'Cancelled')
  end

  def cancel_button
    page.find('.request_cancel_button a')
  end
end
