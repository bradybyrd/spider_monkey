class CreateApplicationComponentMappings < ActiveRecord::Migration
  def change
    create_table :application_component_mappings do |t|
      t.integer :application_component_id
      t.integer :project_server_id
      t.integer :script_id
      t.text :data

      t.timestamps
    end
  end
end
