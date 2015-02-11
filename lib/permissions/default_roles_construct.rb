class DefaultRolesConstruct
  attr_reader :permissions_list

  def initialize
    @permissions_list = PermissionsList.new
  end

  def create_default_roles
    DefaultRoles::CoordinatorRole.new(permissions_list).create
    DefaultRoles::DeployerRole.new(permissions_list).create
    DefaultRoles::RequestorRole.new(permissions_list).create
    DefaultRoles::UserRole.new(permissions_list).create
    DefaultRoles::ExecutorRole.new(permissions_list).create
    DefaultRoles::SiteAdmin.new(permissions_list).create
    DefaultRoles::NotVisibleRole.new(permissions_list).create
  end

  def self.destroy_default_roles
    DefaultRoles::CoordinatorRole.destroy
    DefaultRoles::DeployerRole.destroy
    DefaultRoles::RequestorRole.destroy
    DefaultRoles::UserRole.destroy
    DefaultRoles::ExecutorRole.destroy
    DefaultRoles::SiteAdmin.destroy
    DefaultRoles::NotVisibleRole.destroy
  end

  def create_admin_roles
    DefaultRoles::CoordinatorAdminRole.new(permissions_list).create
    DefaultRoles::DeployerAdminRole.new(permissions_list).create
    DefaultRoles::RequestorAdminRole.new(permissions_list).create
    DefaultRoles::UserAdminRole.new(permissions_list).create
    DefaultRoles::ExecutorAdminRole.new(permissions_list).create
  end

  def self.destroy_admin_roles
    DefaultRoles::CoordinatorAdminRole.destroy
    DefaultRoles::DeployerAdminRole.destroy
    DefaultRoles::RequestorAdminRole.destroy
    DefaultRoles::UserAdminRole.destroy
    DefaultRoles::ExecutorAdminRole.destroy
  end
end