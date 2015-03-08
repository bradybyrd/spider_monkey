require 'spec_helper'

feature 'User on procedures page', custom_roles: true do
  given!(:user) { create(:user, :root) }
  given!(:procedure) { create(:procedure, apps: [app]) }
  given!(:app) { create(:app, :with_installed_component) }
  given(:component) { app.components.first }
  given(:package) { create(:package) }
  given(:app_packages) { app.packages = [package]; app.save}

  background do
    sign_in user
  end

  describe 'working with steps', js: true do
    scenario 'can create step with selected component' do
      visit edit_procedure_path(procedure)
      click_new_step

      within step_popup do
        select_component(component)
        save_step_and_close_popup
      end

      wait_for_ajax

      expect(step_header(recent_step)).to have_content component.name
    end

    scenario 'can create step with selected package' do
      app_packages
      visit edit_procedure_path(procedure)
      click_new_step

      within step_popup do
        select_object_type_package
        wait_for_ajax
        select_package(package)
        save_step_and_close_popup
      end

      wait_for_ajax

      expect(step_header(recent_step)).to have_content package.name
    end

    scenario 'can edit step with selected component' do
      step = create(:step, floating_procedure: procedure, component: component, request: nil)

      visit edit_procedure_path(procedure)
      click_step_edit(step)

      save_step

      wait_for_ajax

      expect(step_header(step)).to have_content component.name
    end
  end


  def recent_step
    Step.last
  end

  def step_header(step)
    find "#step_#{step.id}_#{step.position}_heading"
  end

  def click_step_edit(step)
    step_header(step).find_css('.step_editable_link').first.click
  end

  def click_new_step
    click_link I18n.t('step.buttons.new')
  end

  def save_step_and_close_popup
    click_button I18n.t('step.buttons.add_and_close')
  end

  def save_step
    step_popup.click_button I18n.t('step.buttons.save')
  end

  def select_component(component)
    select component.name, from: 'step_component_id'
  end

  def select_package(package)
    select package.name, from: 'step_package_id'
  end

  def step_popup
    find '#facebox'
  end

  def select_object_type_package
    select 'Package', from: 'step_related_object_type'
  end
end
