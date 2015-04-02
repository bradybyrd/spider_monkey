class CreateIndexesJoinTables < ActiveRecord::Migration
  def change

    add_index :role_permissions, :permission_id
    add_index :role_permissions, :role_id

    add_index :group_roles, :role_id
    add_index :group_roles, :group_id

  end
end