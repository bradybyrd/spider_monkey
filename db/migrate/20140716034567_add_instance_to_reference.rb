class AddInstanceToReference < ActiveRecord::Migration
  def change
    add_column :references, :package_instance_id, :integer
  end
end
