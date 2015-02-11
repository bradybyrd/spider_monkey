class CreateInstanceReferences < ActiveRecord::Migration
  def change
    create_table :instance_references do |t|
      t.string :name, limit: 255, null: false
      t.string :url, null: false
      t.references :package_instance, null: false, index: true
      t.references :server, nul: false, index: true
      t.references :reference, null: false, index: false

      t.timestamps
    end
  end
end
