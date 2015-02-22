class RemoveTerminateSessionFlagFromUser < ActiveRecord::Migration
  def change
    remove_column :users, :terminate_session
  end
end
