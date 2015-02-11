class CreatePackageInstances < ActiveRecord::Migration
  def change
    create_table :package_instances do |t|
      t.string :name
      t.string :instance_name
      t.boolean :active

      t.timestamps
    end
  end
end
