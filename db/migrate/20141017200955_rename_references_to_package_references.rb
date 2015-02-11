class RenameReferencesToPackageReferences < ActiveRecord::Migration
  def self.up
    rename_table :references, :package_references
  end

  def self.down
    rename_table :package_references, :references
  end
end
