class AddAaaToPackageContent < ActiveRecord::Migration
  def self.up
    add_column :package_contents, :archive_number, :string
    add_column :package_contents, :archived_at, :datetime
    add_index :package_contents, :archive_number
    add_index :package_contents, :archived_at
  end

  def self.down    
    remove_index :package_contents, :archive_number
    remove_index :package_contents, :archived_at
    remove_column :package_contents, :archived_at
    remove_column :package_contents, :archive_number
  end
end
