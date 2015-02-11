require 'spec_helper'

feature 'User on a request list page', custom_roles: true do
  scenario 'clicking on request will not open it without Inspect Request permission', js: true do
    user = given_user_with_permission_to_view_request_list
    request = given_request_assigned_to_user(user)

    logged_in(user)
    on_a_request_list_page
    clicks_on_request_in_the_list(request)

    expect(request_list).to have_request(request)
  end

  scenario 'opens a request with Inspect Request permission', js: true do
    user = given_user_with_permission_to_inspect_request
    request = given_request_assigned_to_user(user)

    logged_in(user)
    on_a_request_list_page
    clicks_on_request_in_the_list(request)

    expect(page).to be_a_request_page
  end

  def given_user_with_permission_to_view_request_list
    user = create(:user, :non_root, :with_role_and_group)
    user_permissions = TestPermissionGranter.new(user.groups.first.roles.first.permissions)
    user_permissions << 'Requests' << 'View Requests list' << 'View created Requests list'

    user
  end

  def given_user_with_permission_to_inspect_request
    user = create(:user, :non_root, :with_role_and_group)
    user_permissions = TestPermissionGranter.new(user.groups.first.roles.first.permissions)
    user_permissions << 'Requests' << 'View Requests list' << 'View created Requests list' << 'Inspect Request'

    user
  end

  def given_request_assigned_to_user(user)
    environment = create(:environment)
    request = create(:request, :with_assigned_app, user: user, environment: environment, name: 'Have fun with specs!')
    app = request.apps.first
    app.environments = [environment]

    request
  end

  def logged_in(user)
    sign_in(user)
  end

  def on_a_request_list_page
    visit request_dashboard_path
  end

  def clicks_on_request_in_the_list(request)
    find("td[title='#{request.name}']").click
  end

  def request_list
    find('.requestList')
  end

  def have_request(request)
    have_content(request.name)
  end

  def be_a_request_page
    have_css('#request_title')
  end
end
