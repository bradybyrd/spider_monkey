class AddMessagingToGlobalSettings < ActiveRecord::Migration
  def change
    add_column :global_settings, :messaging_enabled, :boolean, default: false
  end
end
