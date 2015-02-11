class CreateDeploymentWindow < ActiveRecord::Migration
  def change
    create_table "deployment_window_events", :force => true do |t|
      t.integer  "occurrence_id"
      t.integer  "environment_id"
      t.string   "state"
      t.datetime "start_at"
      t.datetime "finish_at"
      t.datetime "created_at",      :null => false
      t.datetime "updated_at",      :null => false
      t.integer  "cached_duration"
      t.text     "reason"
    end

    add_index "deployment_window_events", ["environment_id"], :name => "DW_EVENT_ENV_ID"
    add_index :deployment_window_events, :start_at, name: :i_dw_event_start_at
    add_index :deployment_window_events, :finish_at, name: :i_dw_event_finish_at

    create_table "deployment_window_occurrences", :force => true do |t|
      t.integer  "series_id"
      t.integer  "position"
      t.string   "state"
      t.datetime "start_at"
      t.datetime "finish_at"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    add_index "deployment_window_occurrences", ["series_id"], :name => "DW_OCCUR_SERIES_ID"

    create_table "deployment_window_series", :force => true do |t|
      t.string   "name"
      t.string   "behavior"
      t.datetime "start_at"
      t.datetime "finish_at"
      t.boolean  "recurrent",        :default => false, :null => false
      t.text     "schedule"
      t.integer  "duration_in_days"
      t.datetime "created_at",                          :null => false
      t.datetime "updated_at",                          :null => false
      t.string   "archive_number"
      t.boolean  "occurrences_ready", :default => true, :null => false
      t.datetime "archived_at"
    end

    add_column :requests, :deployment_window_event_id, :integer unless column_exists? :requests, :deployment_window_event_id, :integer
    add_column :requests, :notify_on_dw_fail, :boolean, :default => false, :null => false
    add_column :requests, :automatically_start_errors, :text
    add_index "requests", ["deployment_window_event_id"], :name => "REQUESTS_DWE_ID"

  end

end
