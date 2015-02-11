class CreateRoutes < ActiveRecord::Migration
  def change
    create_table :routes do |t|
      t.string :name, :null => false
      t.integer :app_id, :null => false
      t.string :description
      t.string :route_type, :null => false, :default => 'open'
      t.string :archive_number
      t.datetime :archived_at
      t.timestamps
    end
    add_index :routes, :name, :name => 'I_ROUTE_NAME'
    add_index :routes, :app_id, :name => 'I_ROUTE_APP_ID'
    add_index :routes, :route_type, :name => 'I_ROUTE_TYPE'
    add_index :routes, :archive_number, :name => 'I_ROUTE_ARCH_NUM'
    add_index :routes, :archived_at, :name => 'I_ROUTE_ARCH_AT'
  end
end
