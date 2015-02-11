require "spec_helper"

describe DefaultRoles::RoleCreator do
  class TestRoleCreator < DefaultRoles::RoleCreator
    ID = 1000
    NAME = 'Test'
  end

  let(:role_creator) { TestRoleCreator.new }
  let!(:permission1) { create :permission, name: 'Permission1' }
  let!(:permission2) { create :permission, name: 'Permission2' }
  let(:test_permissions) {
    [ permission1, permission2 ].map { |permission| permission.attributes.symbolize_keys }
  }
  let(:expected_permission_ids) { [permission1.id, permission2.id] }

  before do
    role_creator.stub(:permissions).and_return(test_permissions)
  end

  describe '#permission_ids' do
    it 'returns array of permission ids' do
      expect(role_creator.permission_ids).to eq expected_permission_ids
    end
  end

  describe '#create' do
    it 'creates role' do
      expect {
        role_creator.create
      }.to change(Role, :count).by(1)
      created_role = Role.find(TestRoleCreator::ID)
      expect(created_role.name).to eq TestRoleCreator::NAME
    end

    it 'update permissions of created role' do
      allow(role_creator).to receive(:update_permissions)
      role_creator.create
    end
  end

  describe '#update_permissions' do
    it 'updates role permissions' do
      role = create :role
      stub_const("TestRoleCreator::ID", role.id)
      role_creator.update_permissions
      expect(role.permission_ids).to match_array expected_permission_ids
    end
  end

  describe '#permissions' do
    it 'raise not implemented exception' do
      expect {
        DefaultRoles::RoleCreator.new.permissions
      }.to raise_error NotImplementedError
    end
  end

  describe '.destroy' do
    it 'destroys previously created role' do
      role = create :role
      stub_const("TestRoleCreator::ID", role.id)
      stub_const("TestRoleCreator::NAME", role.name)

      expect {
        TestRoleCreator.destroy
      }.to  change(Role, :count).by(-1)
    end
  end
end
