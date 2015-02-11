class CreateRouteGates < ActiveRecord::Migration
  def change
    create_table :route_gates do |t|
      t.integer :route_id, :null => false
      t.integer :environment_id, :null => false
      t.string :description
      t.integer :position, :default => 0, :null => false
      t.boolean :different_level_from_previous, :default => true, :null => false
      t.string :archive_number
      t.datetime :archived_at
      t.timestamps
    end
    add_index :route_gates, :route_id, :name => 'I_RG_ROUTE_ID'
    add_index :route_gates, :environment_id, :name => 'I_RG_ENVIRONMENT_ID'
    add_index :route_gates, :position, :name => 'I_RG_POSITION'
    add_index :route_gates, :different_level_from_previous, :name => 'I_RG_DLFPRV'
    add_index :route_gates, :archive_number, :name => 'I_RG_ARCH_NUM'
    add_index :route_gates, :archived_at, :name => 'I_RG_ARCH_AT'
  end
end
