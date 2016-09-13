class RakeTaskAndIndexesForPreferences < ActiveRecord::Migration
  def self.up
    add_index :preferences, [:user_id, :position]
    add_index :preferences, :text
    add_index :preferences, [:user_id, :active]
    add_index :preferences, :preference_type
    
    change_column :preferences, :text, :string, :nil => false
    change_column :preferences, :preference_type, :string, :nil => false
        
    # fixes renamed table column headings and resets users with existing preferences
    # there is no meaningful undo of this rake task as the bad values will cause a crash
    #Rake::Task['app:data_repairs:repair_legacy_request_list_preferences'].invoke
  end

  def self.down
    remove_index :preferences, [:user_id, :position]
    remove_index :preferences, :text
    remove_index :preferences, [:user_id, :active]
    remove_index :preferences, :preference_type
    
    change_column :preferences, :text, :string, :nil => true
    change_column :preferences, :preference_type, :string, :nil => true
  end
end
