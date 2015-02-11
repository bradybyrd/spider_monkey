class RemoveEnvironmentGroupTables < ActiveRecord::Migration
  def self.up
    
    # rename all potentially duplicate environments with their group name
    Rake::Task['app:data_repairs:add_environment_group_names_to_environment_names'].invoke
    
    drop_table :environment_groups
    drop_table :grouped_environments
    drop_table :app_environment_groups

    remove_index :requests, ["environment_group_id"]
    remove_column :requests, :environment_group_id
    
    remove_index :assigned_environments, ["environment_group_id"]
    remove_column :assigned_environments, :environment_group_id
    
  end

  def self.down

    create_table "environment_groups", :force => true do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "active",     :default => true
    end

    create_table "grouped_environments", :force => true do |t|
      t.integer  "environment_group_id"
      t.integer  "environment_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "grouped_environments", ["environment_group_id"], :name => "index_grouped_environments_on_environment_group_id"
    add_index "grouped_environments", ["environment_id"], :name => "index_grouped_environments_on_environment_id"

    create_table "app_environment_groups", :force => true do |t|
      t.integer  "app_id"
      t.integer  "environment_group_id"
      t.integer  "environment_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "app_environment_groups", ["app_id"], :name => "index_app_environment_groups_on_app_id"
    add_index "app_environment_groups", ["environment_group_id"], :name => "index_app_environment_groups_on_environment_group_id"
    add_index "app_environment_groups", ["environment_id"], :name => "index_app_environment_groups_on_environment_id"

    add_column :requests, :environment_group_id, :integer
    add_index "requests", ["environment_group_id"], :name => "index_requests_on_environment_group_id"
    
    add_column :assigned_environments, :environment_group_id, :integer
    add_index :assigned_environments, ["environment_group_id"], :name => "index_assigned_environments_on_environment_group_id"
  end
end
