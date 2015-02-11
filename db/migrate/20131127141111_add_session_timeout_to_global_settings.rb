class AddSessionTimeoutToGlobalSettings < ActiveRecord::Migration
  def change
    add_column :global_settings, :session_timeout, :integer
  end
end
