require 'permission_persister'

class MigrationPermissionPersister
  def persist
    if MsSQLAdapter
      mssql_persist_permissions
    else
      permission_persister.persist
    end
  end

  private

  def mssql_persist_permissions
    Permission.connection.with_identity_insert_enabled(Permission.table_name) do
      permission_persister.persist
    end
  end

  def permission_persister
    PermissionPersister.new
  end
end