class AddAaaToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :archive_number, :string
    add_column :categories, :archived_at, :datetime
    remove_column :categories, :active
    add_index :categories, :archive_number
    add_index :categories, :archived_at
  end

  def self.down    
    remove_index :categories, :archived_at
    remove_index :categories, :archive_number
    remove_column :categories, :archived_at
    remove_column :categories, :archive_number
    add_column :categories, :active , :boolean
  end
end
