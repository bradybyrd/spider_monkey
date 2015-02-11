class CreateTeamGroupAppEnvRoles < ActiveRecord::Migration
  def change
    create_table :team_group_app_env_roles do |t|
      t.integer :role_id,                     null: false
      t.integer :team_group_id,               null: false
      t.integer :application_environment_id,  null: false

      t.timestamps
    end

    # add_index :team_group_app_env_roles, :team_group_id
    # add_index :team_group_app_env_roles, :application_environment_id
    # add_index :team_group_app_env_roles, :role_id
  end

end
