require 'spec_helper'

feature 'User on metadata page', custom_roles: true do
  # adding application_environment to be sure that all metadata objects use global permissions
  # granter during can?(:action Object.new)
  given!(:application_environment) { create(:application_environment) }

  given!(:user) { create(:user, :with_role_and_group) }
  given(:permissions) { TestPermissionGranter.new(user.groups.first.roles.first.permissions) }

  background do
    permissions << 'Environment' << 'Access Metadata'

    sign_in user
  end

  describe 'Access Metadata' do
    scenario 'can see manage links' do
      grant_metadata_permissions

      visit manage_metadata_path

      expect(page).to have_manage_categories_link
      expect(page).to have_manage_environment_types_link
      expect(page).to have_manage_plan_templates_link
      expect(page).to have_manage_lists_link
      expect(page).to have_manage_pkg_contents_link
      expect(page).to have_manage_phases_link
      expect(page).to have_manage_procedures_link
      expect(page).to have_manage_processes_link
      expect(page).to have_manage_releases_link
      expect(page).to have_manage_req_templates_link
      expect(page).to have_manage_tickets_link
      expect(page).to have_manage_version_tags_link
      expect(page).to have_manage_work_tasks_link
      expect(page).to have_manage_dw_link
    end

    scenario 'cannot see manage links' do
      visit manage_metadata_path

      expect(page).not_to have_manage_categories_link
      expect(page).not_to have_manage_environment_types_link
      expect(page).not_to have_manage_plan_templates_link
      expect(page).not_to have_manage_lists_link
      expect(page).not_to have_manage_pkg_contents_link
      expect(page).not_to have_manage_phases_link
      expect(page).not_to have_manage_procedures_link
      expect(page).not_to have_manage_processes_link
      expect(page).not_to have_manage_releases_link
      expect(page).not_to have_manage_req_templates_link
      expect(page).not_to have_manage_tickets_link
      expect(page).not_to have_manage_version_tags_link
      expect(page).not_to have_manage_work_tasks_link
      expect(page).not_to have_manage_dw_link
    end
  end

  private

  def grant_metadata_permissions
    manage_permissions = [ 'View Categories list', 'View Environment Types list', 'View Plan Templates list',
                           'View Lists list', 'View Package Contents list', 'View Phases list',
                           'View Procedures list', 'View Processes list', 'View Releases list',
                           'View Request Templates list', 'View Tickets list', 'View Version Tags list',
                           'View Work Tasks list', 'View Deployment Windows list' ]
    manage_permissions.each do |permission|
      permissions.add_from_scope 'Access Metadata', permission
    end
  end

  def have_manage_categories_link
    have_link 'Manage Categories'
  end

  def have_manage_environment_types_link
    have_link 'Manage Environment Types'
  end

  def have_manage_plan_templates_link
    have_link 'Manage Plan Templates'
  end

  def have_manage_lists_link
    have_link 'Manage Lists'
  end

  def have_manage_pkg_contents_link
    have_link 'Manage Package Contents'
  end

  def have_manage_phases_link
    have_link 'Manage Phases'
  end

  def have_manage_procedures_link
    have_link 'Manage Procedures'
  end

  def have_manage_processes_link
    have_link 'Manage Processes'
  end

  def have_manage_releases_link
    have_link 'Manage Releases'
  end

  def have_manage_req_templates_link
    have_link 'Manage Request Templates'
  end

  def have_manage_tickets_link
    have_link 'Manage Tickets'
  end

  def have_manage_version_tags_link
    have_link 'Manage Version Tags'
  end

  def have_manage_work_tasks_link
    have_link 'Manage Work Tasks'
  end

  def have_manage_dw_link
    have_link 'Manage Deployment Windows'
  end
end