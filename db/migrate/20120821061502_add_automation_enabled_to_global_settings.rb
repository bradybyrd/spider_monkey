class AddAutomationEnabledToGlobalSettings < ActiveRecord::Migration
  def self.up
  	add_column :global_settings, :automation_enabled, :boolean, :default => false
  	self.set_automation_enabled_check_box
  end

  def self.down
  	remove_column :global_settings, :automation_enabled
  end

  def self.set_automation_enabled_check_box
  	if GlobalSettings.capistrano_enabled? || GlobalSettings.hudson_enabled?
  		GlobalSettings.update_all("automation_enabled = #{RPMTRUE}")
  	end
  end
end
