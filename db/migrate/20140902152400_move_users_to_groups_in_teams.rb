require 'yaml'
require 'migration/sql_helpers'
require File.join(File.dirname(__FILE__), '20140829075903_migrate_app_assignments_to_teams')
require File.join(File.dirname(__FILE__), '/../migration_handlers/20140902152400/load_handlers')

class MoveUsersToGroupsInTeams < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      DefaultGroupsHandler.new.apply
      SiteAdminGroupHandler.new.apply
      RootGroupHandler.new.apply
      TeamGroupsHandler.new.apply
      TeamGroupsHandler.new.remove_assigned_app_dublicates
    end

    drop_table :teams_roles
    drop_table :teams_users
  end

  def down
    create_team_users unless ActiveRecord::Base.connection.table_exists?(:teams_users)
    create_team_roles unless ActiveRecord::Base.connection.table_exists?(:teams_roles)
    
    ActiveRecord::Base.transaction do
      TeamGroupsHandler.new.revert
      SiteAdminGroupHandler.new.revert
      RootGroupHandler.new.revert
      DefaultGroupsHandler.new.revert
    end  
  end

  def create_team_users
    create_table :teams_users do |t|
      t.integer :team_id
      t.integer :user_id
      t.timestamps
    end
    add_index :teams_users, :team_id
    add_index :teams_users, :user_id
  end

  def create_team_roles
    create_table :teams_roles do |t|
      t.integer :teams_user_id
      t.integer :app_id
      t.text    :roles
      t.timestamps
    end
    add_index :teams_roles, :app_id
    add_index :teams_roles, :teams_user_id
  end  

end

