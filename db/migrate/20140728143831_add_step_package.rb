class AddStepPackage < ActiveRecord::Migration
  def up
    add_column :steps, :package_instance_id, :integer
    add_column :steps, :package_id, :integer
    add_index :steps, :package_id
    add_index :steps, :package_instance_id
  end

  def down
    remove_index :steps, :package_id
    remove_index :steps, :package_instance_id

    remove_column :steps, :package_instance_id
    remove_column :steps, :package_id
  end

end
