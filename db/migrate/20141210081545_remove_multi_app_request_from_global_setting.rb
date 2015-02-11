class RemoveMultiAppRequestFromGlobalSetting < ActiveRecord::Migration
  def up
    remove_column :global_settings, :multi_app_requests
  end

  def down
    add_column :global_settings, :multi_app_requests, :boolean
  end
end
