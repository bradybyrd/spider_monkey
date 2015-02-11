require 'spec_helper'

feature 'Role permissions list', js: true do
  given(:user) { create(:user, :non_root ) }
  given(:role_form) { RoleFormPage.new }
  given(:permissions) do
    [
      {
        'name' => 'Main Tabs',
        'items' => [
          {'id' => 2, 'name' => 'Dashboard'},
          {'id' => 3, 'name' => 'System'}
        ]
      },
      {
        'name' => 'Dashboard Section', 'depends_on_id' => 2,
        'items' => [
          {
            'id' => 5, 'name' => 'Parent Permission',
            'items' => [
              {'id' => 6, 'name' => 'Child Permission'}
            ]
          },
          {
            'id' => 7, 'name' => 'With nested',
            'items' => [
              {'id' => 8, 'name' => 'Permission'},
              {'id' => 9, 'name' => 'Permission'}
            ]
          }
        ]
      },
      {
        'name' => 'System Section', 'depends_on_id' => 3,
        'items' => [
          {'id' => 12, 'name' => 'Permission'},
          {'id' => 13, 'name' => 'Permission'}
        ]
      }
    ]
  end

  background do
    Ability.any_instance.stub(:can?).and_return(true)
    PermissionsList.any_instance.stub(:permissions_tree).and_return(permissions)
    PermissionPersister.new.persist

    sign_in user
  end

  describe "Permission checkboxes" do
    scenario "All permissions should be checked by default" do
      page.has_css?(".permissions input", :count => 10)
      role_form.all_permissions.each do |checkbox|
        expect(checkbox).to be_checked
      end
    end

    scenario "Toggle all permissions" do
      role_form.visit_page
      role_form.clear_all_permissions
      role_form.all_permissions.each do |checkbox|
        expect(checkbox).not_to be_checked
      end

      role_form.select_all_permissions
      role_form.all_permissions.each do |checkbox|
        expect(checkbox).to be_checked
      end
    end

    scenario "Select all should select all subsections" do
      role_form.visit_page

      role_form.clear_all_permissions
      expect(role_form.section('Dashboard Section')[:class]).to match 'disabled'
      expect(role_form.section('System Section')[:class]).to match 'disabled'

      role_form.select_all_permissions
      expect(role_form.section('Dashboard Section')[:class]).not_to match 'disabled'
      expect(role_form.section('System Section')[:class]).not_to match 'disabled'
    end

    scenario "Select main section should select all subsections" do
      role_form.visit_page

      role_form.clear_section 'Main Tabs'
      expect(role_form.section('Dashboard Section')[:class]).to match 'disabled'
      expect(role_form.section('System Section')[:class]).to match 'disabled'

      role_form.select_section 'Main Tabs'
      expect(role_form.section('Dashboard Section')[:class]).not_to match 'disabled'
      expect(role_form.section('System Section')[:class]).not_to match 'disabled'
    end

    scenario "Select section permissions" do
      role_form.visit_page
      system_section = role_form.section 'System Section'
      role_form.clear_section system_section
      role_form.section_permissions(system_section).each do |checkbox|
        expect(checkbox).not_to be_checked
      end

      role_form.select_section system_section
      role_form.section_permissions(system_section).each do |checkbox|
        expect(checkbox).to be_checked
      end
    end

    scenario "Main section should enable/disable subsection" do
      role_form.visit_page
      role_form.toggle('Main Tabs') # expand
      uncheck('Dashboard')
      expect(role_form.section('System Section')[:class]).not_to match('disabled') # it does not touch another section

      dashboard_section = role_form.section('Dashboard Section')
      expect(dashboard_section[:class]).to match('disabled')

      check('Dashboard')
      expect(dashboard_section[:class]).not_to match('disabled')
    end

    scenario "Main section should select/clear all permissions in subsection" do
      role_form.visit_page
      role_form.toggle('Main Tabs') # expand
      uncheck('Dashboard')

      dashboard_section = role_form.section('Dashboard Section')
      role_form.section_permissions(dashboard_section).each do |checkbox|
        expect(checkbox).not_to be_checked
        expect(checkbox).to be_disabled
      end


      check('Dashboard')
      role_form.section_permissions(dashboard_section).each do |checkbox|
        expect(checkbox).to be_checked
        expect(checkbox).not_to be_disabled
      end
    end

    scenario "Nested permissions should be unchecked if parent is unchecked" do
      role_form.visit_page
      role_form.toggle('Dashboard Section')

      uncheck('With nested')
      role_form.section_children_permissions('With nested').each do |checkbox|
        expect(checkbox).not_to be_checked
        expect(checkbox).not_to be_disabled
      end
    end

    scenario "All nested permissions should be checked if I check parent" do
      role_form.visit_page
      role_form.toggle('Dashboard Section')

      uncheck('With nested')
      check('With nested')
      role_form.section_children_permissions('With nested').each do |checkbox|
        expect(checkbox).to be_checked
        expect(checkbox).not_to be_disabled
      end
    end

    scenario 'Parent permissions should be checked if child is checked' do
      role_form.visit_page
      role_form.toggle('Dashboard Section')

      check('Child Permission')

      expect(role_form.checkbox('Parent Permission')).to be_checked
    end
  end


  describe "Expand and Collapse" do
    scenario "All sections should be collapsed by default" do
      role_form.visit_page
      expect(role_form.section_content('Main Tabs')).not_to be_visible
      expect(role_form.section_content('Dashboard Section')).not_to be_visible
      expect(role_form.section_content('System Section')).not_to be_visible
    end

    scenario "Expand and collapse section" do
      role_form.visit_page
      main_section = role_form.section('Main Tabs')
      role_form.toggle(main_section) # expand
      expect(role_form.section_content(main_section)).to be_visible

      role_form.toggle(main_section) # collapse
      expect(role_form.section_content(main_section)).not_to be_visible
    end
  end
end