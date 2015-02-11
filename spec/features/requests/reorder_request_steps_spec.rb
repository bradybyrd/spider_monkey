require 'spec_helper'

feature 'Reorder request steps' do
  given!(:admin) { create(:user) }
  given!(:request) { create(:request) }

  background do
    request.steps = create_pair(:step)

    sign_in admin
  end

  scenario 'Reorder request steps on request page' do
    visit request_path(request)

    reorder_step_button.click

    within '#step' do
      expect(page).to have_done_reordering_button
    end

    within '#sidebar' do
      expect(page).to have_manage_procedures_button
    end

  end

  def reorder_step_button
    page.find('a#reorder_steps')
  end

  def have_done_reordering_button
    have_css('.done_reordering')
  end

  def have_manage_procedures_button
    have_css('.manage_procedures')
  end

end
