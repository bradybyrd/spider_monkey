require 'spec_helper'
require 'accessible_app_environment_query'

describe UserPermissionsQuery, custom_roles: true do
  let!(:user) { create(:old_user, :not_admin_with_role_and_group) }
  let(:user_permissions_query) { UserPermissionsQuery.new(user) }
  let(:user_permissions) { user.groups.first.roles.first.permissions }

  let!(:other_user) { create(:old_user, :not_admin_with_role_and_group) }
  let(:other_user_permissions) { other_user.groups.first.roles.first.permissions }

  let!(:subject_list_permission) { create(:permission, name: 'Subject List', action: :list, subject: 'Subject') }
  let!(:subject_view_permission) { create(:permission, name: 'Subject View', action: :view, subject: 'Subject') }
  let!(:other_subject_delete_permission) { create(:permission, name: 'Other Subject Delete', action: :delete, subject: 'Other Subject') }
  let!(:other_subject_edit_permission) { create(:permission, name: 'Other Subject Edit', action: :edit, subject: 'Other Subject') }

  before do
    user_permissions << subject_list_permission
    user_permissions << subject_view_permission
    user_permissions << other_subject_delete_permission

    other_user_permissions << subject_view_permission
    other_user_permissions << other_subject_delete_permission
    other_user_permissions << other_subject_edit_permission
  end

  describe '#user_permissions' do
    it 'returns permissions for user' do
      user_permissions_query.user_permissions.should =~ user_permissions
    end
  end

  describe '#get_all' do
    it 'returns app permissions' do
      permission_relation = mock 'Permissions Relation'
      permission_relation.stub(:all).and_return user_permissions
      user_permissions_query.should_receive(:user_permissions).and_return permission_relation
      user_permissions_query.get_all.should == user_permissions
    end
  end

  describe '#get_by_subject_and_action' do
    it 'returns permission for particular subject and action' do
      result = user_permissions_query.get_by_subject_and_action('Other Subject', :delete)
      result.size.should == 1
      result.first.name.should == 'Other Subject Delete'
    end
  end
end