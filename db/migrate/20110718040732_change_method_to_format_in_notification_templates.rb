class ChangeMethodToFormatInNotificationTemplates < ActiveRecord::Migration
  def self.up
    rename_column :notification_templates, :method, :format
  end

  def self.down
    rename_column :notification_templates, :format, :method
  end
end
