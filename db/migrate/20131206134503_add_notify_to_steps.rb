class AddNotifyToSteps < ActiveRecord::Migration
  def change
    add_column :steps, :skip_email_notification, :boolean, default: false, null: false
  end
end
