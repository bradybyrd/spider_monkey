class AddAaaToReleases < ActiveRecord::Migration
  def self.up
    add_column :releases, :archive_number, :string
    add_column :releases, :archived_at, :datetime
    remove_column :releases, :active
    add_index :releases, :archive_number
    add_index :releases, :archived_at
  end

  def self.down
    remove_index :releases, :archived_at
    remove_index :releases, :archive_number
    add_column :releases, :active, :boolean
    remove_column :releases, :archived_at
    remove_column :releases, :archive_number
    
  end
end
