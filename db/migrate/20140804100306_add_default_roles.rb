class AddDefaultRoles < ActiveRecord::Migration
  def up
    return if Permission.count == 0 # test env does not have permissions

    MigrationPermissionPersister.new.persist
    DefaultRolesConstruct.new.create_default_roles
  end

  def down
    DefaultRolesConstruct.destroy_default_roles
  end
end
