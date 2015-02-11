require 'spec_helper'

feature 'User views a request step with a package' do
  include StepHelper

  context 'package is invalid' do
    scenario 'it shows the step highlighted in red', js: true do
      sign_in create(:user, :root)
      step = create_step_with_invalid_package

      visit request_path(step.request)

      expect(page).to have_invalid_step_row_for(step)
    end

    scenario 'it does not show the package instance select box', js: true do
      sign_in create(:user, :root)
      step = create_step_with_invalid_package

      edit_step(step)

      expect(page).not_to have_package_instance_select
    end
  end

  context 'package is valid' do
    scenario 'it does not show the step highlighted in red', js: true do
      sign_in create(:user, :root)
      step = create_step_with_valid_package

      visit request_path(step.request)

      expect(page).not_to have_invalid_step_row_for(step)
    end

    scenario 'it shows the package instance select box', js: true do
      sign_in create(:user, :root)
      step = create_step_with_valid_package

      edit_step(step)

      expect(page).to have_package_instance_select
    end
  end

  def edit_step(step)
    visit edit_request_step_path(step.request, step)
  end

  def have_package_instance_select
    have_css('#package_instance_selection select')
  end

  def have_invalid_step_row_for(step)
    have_css('.step.invalid', text: step.name)
  end
end
