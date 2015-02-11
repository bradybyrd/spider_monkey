class CreateIndexesJoinTables < ActiveRecord::Migration
  def change

    add_index :role_permissions, :permission_id
    add_index :role_permissions, :role_id

    add_index :group_roles, :role_id
    add_index :group_roles, :group_id

    add_index :team_group_app_env_roles, :team_group_id
    add_index :team_group_app_env_roles, :application_environment_id
    add_index :team_group_app_env_roles, :role_id

  end
end