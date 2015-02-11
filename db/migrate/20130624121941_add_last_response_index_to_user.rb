class AddLastResponseIndexToUser < ActiveRecord::Migration
  def change
    # adding indexes for common filters and session freshness routines
    add_index :users, 'last_response_at', :name => 'I_USERS_ON_LRA'
    add_index :users, 'root', :name => 'I_USERS_ROOT'
    add_index :users, 'admin', :name => 'I_USERS_ADMIN'
    add_index :users, 'system_user', :name => 'I_USERS_SYSTEM_USR'
    add_index :users, 'email', :name => 'I_USERS_EMAIL'
    add_index :users, 'first_name', :name => 'I_USERS_FIRST'
    add_index :users, 'last_name', :name => 'I_USERS_LAST'
    add_index :users, ['last_name', 'first_name'], :name => 'I_USERS_LAST_FIRST'
  end
end
