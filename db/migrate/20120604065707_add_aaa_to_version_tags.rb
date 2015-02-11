class AddAaaToVersionTags < ActiveRecord::Migration
  def self.up
    add_column :version_tags, :archive_number, :string
    add_column :version_tags, :archived_at, :datetime
    remove_column :version_tags,:active 
    add_index :version_tags, :archive_number
    add_index :version_tags, :archived_at
  end

  def self.down
    remove_index :version_tags, :archive_number
    remove_index :version_tags, :archived_at
    add_column :version_tags,:active ,:boolean
    remove_column :version_tags, :archived_at
    remove_column :version_tags, :archive_number
    
  end
end
