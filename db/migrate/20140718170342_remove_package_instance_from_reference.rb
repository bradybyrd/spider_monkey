class RemovePackageInstanceFromReference < ActiveRecord::Migration
  def up
    remove_column :references, :package_instance_id
  end

  def down
    add_column :references, :package_instance_id, :int
  end
end
