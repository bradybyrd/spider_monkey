class UpdatePackagePermissions < ActiveRecord::Migration
  def up
    MigrationPermissionPersister.new.persist
  end

  def down
  end
end
