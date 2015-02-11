class DropUnneededTablesLifecyles < ActiveRecord::Migration
  def self.up
    drop_table :activities_lifecycle_members
    drop_table :lifecycle_activities
    drop_table :lifecycle_environments
  end

  def self.down
    create_table "activities_lifecycle_members", :id => false, :force => true do |t|
      t.integer "activity_id",         :null => false
      t.integer "lifecycle_member_id", :null => false
    end

    add_index "activities_lifecycle_members", ["activity_id"], :name => "i_act_lm_activity_id"
    add_index "activities_lifecycle_members", ["lifecycle_member_id"], :name => "i_act_lm_id"

    create_table "lifecycle_activities", :force => true do |t|
      t.integer  "lifecycle_id"
      t.integer  "activity_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "lifecycle_activities", ["activity_id"], :name => "i_la_activity_id"
    add_index "lifecycle_activities", ["lifecycle_id"], :name => "i_la_lifecycle_id"

    create_table "lifecycle_environments", :force => true do |t|
      t.integer  "lifecycle_id"
      t.integer  "environment_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "environment_group_id"
    end

    add_index "lifecycle_environments", ["environment_group_id"], :name => "i_len_env_group_id"
    add_index "lifecycle_environments", ["environment_id"], :name => "i_len_environment_id"
    add_index "lifecycle_environments", ["lifecycle_id"], :name => "i_len_l_id"
  end
end
