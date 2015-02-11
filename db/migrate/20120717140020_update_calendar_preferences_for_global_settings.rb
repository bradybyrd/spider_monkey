class UpdateCalendarPreferencesForGlobalSettings < ActiveRecord::Migration
  def up
    change_column :global_settings, "calendar_preferences", :string, :limit => 1000
  end

  def down
    change_column :global_settings, "calendar_preferences", :string
  end
end
