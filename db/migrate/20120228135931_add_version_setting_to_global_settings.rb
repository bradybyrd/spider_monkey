class AddVersionSettingToGlobalSettings < ActiveRecord::Migration
  def self.up
     add_column :global_settings, :limit_versions, :boolean 
  end

  def self.down
     remove_column :global_settings, :limit_versions
  end
end
