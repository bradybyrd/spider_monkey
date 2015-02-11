require 'spec_helper'

feature 'Routes page permissions', custom_roles: true, js: true do
  given!(:user) { create(:old_user, :not_admin_with_role_and_group) }
  given!(:route) { create(:route) }
  given!(:basic_permissions) { [
      create(:permission, name: 'View applications', action: :view, subject: :my_applications ),
      create(:permission, name: 'Environment tab view', action: :view, subject: :environment_tab),
      create(:permission, name: 'Metadata', action: :view, subject: :metadata)
    ] }

  given(:permissions) { user.groups.first.roles.first.permissions }
  given(:permissions_list) { PermissionsList.new}

  given(:view_routes_permission) { create(:permission, name: 'View routes list', action: :list, subject: 'Route') }
  given(:create_route_permission) { create(:permission, name: 'Create route', action: :create, subject: 'Route') }
  given(:edit_route_permission) { create(:permission, name: 'Edit route', action: :edit, subject: 'Route') }
  given(:archive_route_permission) { create(:permission, name: 'Archive/Unarchive route', action: :archive_unarchive, subject: 'Route') }
  given(:delete_route_permission) { create(:permission, name: 'Delete route', action: :delete, subject: 'Route') }
  given(:inspect_route_permission) { create(:permission, permissions_list.permission('Inspect Routes'))}

  background do
    permissions << basic_permissions

    sign_in user
  end

  describe 'route index page' do
    context 'route list' do
      scenario 'when does not user has any route permissions' do
        visit app_routes_path(route.app)

        expect(page).not_to have_css('#routes')
        expect(page).not_to have_content(route.name)
      end

      scenario 'when user has "list routes" permission user can view routes list' do
        permissions << view_routes_permission
        visit app_routes_path(route.app)

        expect(page).to have_css('#routes')
        expect(page).to have_content(route.name)
      end
    end

    context '"Create Route" button' do
      background do
        permissions << view_routes_permission
      end

      scenario 'when does not user has any route permissions except view list' do
        visit app_routes_path(route.app)
        expect(page).not_to have_button 'Create Route'

        visit new_app_route_path(route.app)
        expect(page).not_to have_button 'Create Route'
      end

      scenario 'when user having "create route" permission clicks on "Create route" button' do
        permissions << create_route_permission
        visit app_routes_path(route.app)

        expect(page).to have_button 'Create Route'
        click_on 'Create Route'

        expect(error_messages).not_to include_no_permission_message
        expect(page).to have_new_route_form
      end
    end

    context '"Edit Route" link' do
      background do
        permissions << view_routes_permission
      end

      scenario 'when does not user has any route permissions except view list' do
        visit app_routes_path(route.app)
        expect(page).not_to have_css('.edit_route')

        visit edit_app_route_path(route.app, route)
        expect(page).not_to have_content(route.name)
      end

      scenario 'when user has "edit route" permission user can see "Edit" link' do
        permissions << edit_route_permission
        permissions << inspect_route_permission
        visit app_routes_path(route.app)

        expect(page).to have_edit_route_links
        click_on_edit_route_link(route)

        expect(error_messages).not_to include_no_permission_message
        expect(page).to have_button 'Edit Route'
      end
    end

    context '"Archive/Unarchive Routes" link' do
      background do
        permissions << view_routes_permission
      end

      scenario 'when does not user has any route permissions except view list' do
        visit app_routes_path(route.app)

        expect(page).not_to have_css('.archive_route')
        expect(page).not_to have_css('h3', text: 'Archived')
      end

      scenario 'when user has "Archive/Unarchive Route" permission user can see "Archive" link' do
        permissions << archive_route_permission
        visit app_routes_path(route.app)

        expect(page).not_to have_link('Unarchive')
        expect(page).to have_css('.archive_route')
        page.find("#route_#{ route.id } .archive_route").click

        expect(page).to have_link('Unarchive')
      end
    end

    context '"Delete" link' do
      background do
        permissions << view_routes_permission
        route.archive
      end

      scenario 'when does not user has any route permissions except view list' do
        visit app_routes_path(route.app)
        expect(page).not_to have_css('.delete_route')
      end

      scenario 'when user has "Delete Route" permission user can see "Delete" link' do
        permissions << delete_route_permission
        visit app_routes_path(route.app)

        expect(page).to have_css('.delete_route')
        page.find("#route_#{ route.id } .delete_route").click

        expect(page).not_to have_content('Unathorize')
      end
    end
  end

  def error_messages
    find '.flash_messages'
  end

  def have_new_route_form
    have_css 'form#new_route'
  end

  def include_no_permission_message
    have_content(I18n.t('activerecord.errors.no_access_to_view_page'))
  end

  def click_on_edit_route_link(route)
    page.find("#route_#{ route.id } .edit_route").click
  end

  def have_edit_route_links
    have_css('.edit_route')
  end

end
