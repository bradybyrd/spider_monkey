class RenamePackageColumnName < ActiveRecord::Migration
  def change
    rename_column :packages, :version_format, :instance_name_format
    rename_column :packages, :next_instance, :next_instance_number
  end
end
