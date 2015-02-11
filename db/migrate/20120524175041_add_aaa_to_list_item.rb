class AddAaaToListItem < ActiveRecord::Migration
  def self.up
    add_column :list_items, :archive_number, :string
    add_column :list_items, :archived_at, :datetime
    add_index :list_items, :archive_number
    add_index :list_items, :archived_at
  end

  def self.down    
    remove_index :list_items, :archive_number
    remove_index :list_items, :archived_at
    remove_column :list_items, :archived_at
    remove_column :list_items, :archive_number
  end
end
