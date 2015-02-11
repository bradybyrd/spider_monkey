require 'spec_helper'

feature 'Package edit page permissions', js: true, custom_roles: true do
  given!(:user) { create(:user, :non_root, :with_role_and_group) }
  given!(:reference) { create(:reference) }

  given(:permissions) { user.groups.first.roles.first.permissions }
  given(:permissions_list) { PermissionsList.new }

  given(:basic_permissions) do
    [
      create(:permission, permissions_list.permission('Environment')),
      create(:permission, permissions_list.permission('View Environments list')),
      create(:permission, permissions_list.permission('Edit Package'))
    ]
  end

  given(:reference_managing_permissions) do
    [
      create(:permission, permissions_list.permission('Add Reference')),
      create(:permission, permissions_list.permission('Update Reference')),
      create(:permission, permissions_list.permission('Delete Reference'))
    ]
  end

  background do
    permissions << basic_permissions
    sign_in user
    app = create(:app)
    create(:team_with_apps_and_groups, apps: [app], groups: user.groups)
    create(:application_package, app: app, package: reference.package)
  end

  context 'Reference permissions' do
    context 'w/o managing permissions' do
      scenario 'can only view references data' do
        visit edit_package_path(reference.package)

        expect(page).not_to have_link 'Add Reference'
        expect(references_table).not_to have_delete_link
        expect(references_table).not_to have_edit_link
      end
    end

    context 'with managing permissions' do
      scenario 'can create, edit and delete' do
        permissions << reference_managing_permissions
        visit edit_package_path(reference.package)

        expect(page).to have_link 'Add Reference'
        expect(references_table).to have_delete_link
        expect(references_table).to have_edit_link
      end
    end
  end

  def references_table
    find('.formatted_table.references')
  end

  def have_delete_link
    have_link I18n.t(:delete)
  end

  def have_edit_link
    have_link I18n.t(:edit)
  end
end
