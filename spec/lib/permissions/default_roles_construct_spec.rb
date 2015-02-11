require "spec_helper"

describe DefaultRolesConstruct do
  before { PermissionPersister.new.persist }
  let(:permissions_list) { PermissionsList.new }

  describe '#create_default_roles' do
    it 'creates default roles' do
      expect {
        DefaultRolesConstruct.new.create_default_roles
      }.to change(Role, :count).by(7)
    end
  end

  describe '#destroy_default_roles' do
    it 'destroys default roles' do
      DefaultRolesConstruct.new.create_default_roles
      expect {
        DefaultRolesConstruct.destroy_default_roles
      }.to change(Role, :count).by(-7)
    end
  end

  describe '#create_admin_roles' do
    it 'creates default admin roles' do
      expect {
        DefaultRolesConstruct.new.create_admin_roles
      }.to change(Role, :count).by(5)
    end
  end

  describe '#destroy_admin_roles' do
    it 'destroys default admin roles' do
      DefaultRolesConstruct.new.create_admin_roles
      expect {
        DefaultRolesConstruct.destroy_admin_roles
      }.to change(Role, :count).by(-5)
    end
  end

  describe 'create Coordinator, Deployer, Requestor roles' do
    it 'Coordinator role does not have "Select Instance" or "Select Package" permissions' do
      coordinator_role = create_default_role(DefaultRoles::CoordinatorRole)

      expect(coordinator_role.permissions).not_to include(select_instance_permission)
      expect(coordinator_role.permissions).not_to include(select_package_permission)
    end

    it 'Deployer role does not have "Select Instance" or "Select Package" permissions' do
      deployer_role = create_default_role(DefaultRoles::DeployerRole)

      expect(deployer_role.permissions).not_to include(select_instance_permission)
      expect(deployer_role.permissions).not_to include(select_package_permission)
    end

    it 'Requestor role does not have "Select Instance" or "Select Package" permissions' do
      requestor_role = create_default_role(DefaultRoles::RequestorRole)

      expect(requestor_role.permissions).not_to include(select_instance_permission)
      expect(requestor_role.permissions).not_to include(select_package_permission)
    end
  end

  def create_default_role(role_creator_class)
    role_creator_class.new(permissions_list).create
    Role.find_by_name(role_creator_class::NAME)
  end

  def select_instance_permission
    Permission.find_by_name('Select Instance')
  end

  def select_package_permission
    Permission.find_by_name('Select Package')
  end
end
