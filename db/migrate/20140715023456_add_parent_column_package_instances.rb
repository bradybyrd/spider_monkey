class AddParentColumnPackageInstances < ActiveRecord::Migration
  def change
    add_column :package_instances, :package_id, :integer
  end
end
