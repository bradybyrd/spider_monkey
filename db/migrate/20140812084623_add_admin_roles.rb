class AddAdminRoles < ActiveRecord::Migration
  def up
    return if Permission.count == 0 # test env does not have permissions

    MigrationPermissionPersister.new.persist
    DefaultRolesConstruct.new.create_admin_roles
  end

  def down
    DefaultRolesConstruct.destroy_admin_roles
  end
end