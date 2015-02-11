class AddAaaToProcedures < ActiveRecord::Migration
  def self.up
    add_column :procedures, :archive_number, :string
    add_column :procedures, :archived_at, :datetime
    add_index :procedures, :archive_number
    add_index :procedures, :archived_at
  end

  def self.down
    remove_index :procedures, :archive_number
    remove_index :procedures, :archived_at
    remove_column :procedures, :archived_at
    remove_column :procedures, :archive_number
  end
end
