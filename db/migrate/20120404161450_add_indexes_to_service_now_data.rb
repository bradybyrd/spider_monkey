class AddIndexesToServiceNowData < ActiveRecord::Migration
  def self.up
    add_index :service_now_data, :table_name, :name => "snow_table"
    add_index :service_now_data, :name, :name => "name_search"
    add_index :service_now_data, :sys_id, :name => "foreign_key"
  end

  def self.down
  end
end
