class AddAaaToPhase < ActiveRecord::Migration
  def self.up
    add_column :phases, :archive_number, :string
    add_column :phases, :archived_at, :datetime
    add_index :phases, :archive_number
    add_index :phases, :archived_at
  end

  def self.down
    remove_index :phases, :archive_number
    remove_index :phases, :archived_at
    remove_column :phases, :archived_at
    remove_column :phases, :archive_number
  end
end
