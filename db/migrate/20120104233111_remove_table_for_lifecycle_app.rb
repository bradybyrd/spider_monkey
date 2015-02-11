class RemoveTableForLifecycleApp < ActiveRecord::Migration
  def self.up
    drop_table :lifecycle_apps
  end

  def self.down
    create_table "lifecycle_apps", :force => true do |t|
      t.integer  "lifecycle_id"
      t.integer  "app_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "lifecycle_apps", ["app_id"], :name => "i_la_app_id"
    add_index "lifecycle_apps", ["lifecycle_id"], :name => "i_la_lifecycle_id"
  end
end
