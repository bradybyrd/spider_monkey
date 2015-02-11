class CreatePackages < ActiveRecord::Migration
  def change

    create_table "application_packages" do |t|
      t.integer  "app_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "package_id"
      t.integer  "position"
      t.boolean  "different_level_from_previous", :default => true, :null => false
    end

    create_table "package_properties" do |t|
      t.integer "package_id"
      t.integer "property_id"
      t.integer "position"
    end

    create_table :packages do |t|
      t.string :name
      t.string :version_format
      t.integer :next_instance

      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "active",     :default => true
    end
  end
end
