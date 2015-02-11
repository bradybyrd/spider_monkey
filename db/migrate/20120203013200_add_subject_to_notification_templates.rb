class AddSubjectToNotificationTemplates < ActiveRecord::Migration
  def self.up
    add_column :notification_templates, :subject, :string
  end

  def self.down
    remove_column :notification_templates, :subject
  end
end
