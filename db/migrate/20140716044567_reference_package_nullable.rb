class ReferencePackageNullable < ActiveRecord::Migration
  def change
    change_column :references, :package_id, :integer, :null => true
  end
end
