class RemovePackageInstanceInstanceNameColumn < ActiveRecord::Migration
  def up
    remove_column :package_instances, :instance_name
  end

  def down
    add_column :package_instances, :instance_name, :string
  end
end
