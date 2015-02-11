class CreateVersions < ActiveRecord::Migration
  def self.up
    create_table :versions do |t|
      t.string :name,           :null => false
      t.integer :app_id
      t.integer :app_env_id
      t.integer :installed_component_id
      t.string :artifact_url
      t.boolean  "active",     :default => true,  :null => false
      
      t.timestamps
  end

  def self.down
      drop_table :versions
  end
  end
end
