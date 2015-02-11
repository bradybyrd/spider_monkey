class AddAaaToList < ActiveRecord::Migration
  def self.up
    add_column :lists, :archive_number, :string
    add_column :lists, :archived_at, :datetime
    remove_column :lists, :is_active
    add_index :lists, :archive_number
    add_index :lists, :archived_at
  end

  def self.down    
    remove_index :lists, :archive_number
    remove_index :lists, :archived_at
    remove_column :lists, :archived_at
    remove_column :lists, :archive_number
    add_column :lists, :is_active, :boolean
  end
end
