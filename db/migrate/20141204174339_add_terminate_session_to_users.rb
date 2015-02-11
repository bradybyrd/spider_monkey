class AddTerminateSessionToUsers < ActiveRecord::Migration
  def change
    add_column :users, :terminate_session, :boolean, default: false, null: false
  end
end
