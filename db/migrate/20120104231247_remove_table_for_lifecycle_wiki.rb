class RemoveTableForLifecycleWiki < ActiveRecord::Migration
  def self.up
    drop_table :lifecycle_wikis
  end

  def self.down
    create_table "lifecycle_wikis", :force => true do |t|
      t.text     "content"
      t.string   "subject"
      t.integer  "lifecycle_id"
      t.integer  "user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "lifecycle_wikis", ["lifecycle_id"], :name => "i_lw_lifecycle_id"
  end
end
