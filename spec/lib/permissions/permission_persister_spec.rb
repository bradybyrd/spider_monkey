require 'spec_helper'

describe PermissionPersister do
  describe '#persist' do
    it 'deletes old permissions' do
      old_permission = create(:permission, name: 'what a wonderful but deprecated permission')

      PermissionPersister.new.persist

      expect(Permission.find_by_name(old_permission.name)).to be_nil
    end

    it 'persists the permissions' do
      permission_persister = PermissionPersister.new
      allow(permission_persister).to receive(:permissions_tree).and_return(permissions_tree)

      permission_persister.persist

      expect(permission_persister).to have_received(:permissions_tree)
      expect(Permission.count).to eq 2
    end

    it 'deletes role_permissions' do
      RolePermission.create

      expect { PermissionPersister.new.persist }.to change(RolePermission, :count).to(0)
    end

    def permissions_tree
      [{'name' => 'Main Tabs',
        'items' =>
            [{'id' => 2,
              'name' => 'Dashboard',
              'action' => 'view',
              'subject' => :dashboard_tab},
             {'id' => 3, 'name' => 'Plans', 'action' => 'view', 'subject' => :plans_tab}]
       }]
    end
  end
end