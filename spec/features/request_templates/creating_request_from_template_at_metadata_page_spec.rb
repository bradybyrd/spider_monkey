require 'spec_helper'

feature 'User on a metadata page', custom_roles: true, js: true do
  scenario 'sees the create request button' do
    user = setup_user_for_creating_request_from_a_template
    permissions_list = PermissionsList.new
    permissions = user.groups.first.roles.first.permissions
    permissions << create(:permission, permissions_list.permission('Access Metadata'))
    permissions << create(:permission, permissions_list.permission('View Request Templates list'))
    permissions << create(:permission, permissions_list.permission('Create Requests'))

    sign_in user
    visit request_templates_path

    expect(page).to have_button 'Create Request'
  end

  def setup_user_for_creating_request_from_a_template
    environment = create(:environment)
    app = create(:app, :with_installed_component, environments: [environment])
    user = create_user_with_assigned_app(app)
    create_request_template_for(app, environment)

    user
  end

  def create_user_with_assigned_app(app)
    user = create(:user, :with_role_and_group, apps: [app])
    team = create(:team, groups: user.groups)
    create(:development_team, team: team, app: app)

    user
  end

  def create_request_template_for(app, environment)
    request = create(:request, apps: [app], environment: environment)
    create(:request_template, request: request)
  end
end
