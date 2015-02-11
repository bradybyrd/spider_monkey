class AddAaaToBusinessProcesses < ActiveRecord::Migration
  def self.up
    add_column :business_processes, :archive_number, :string
    add_column :business_processes, :archived_at, :datetime
    remove_column :business_processes, :active
    add_index :business_processes, :archive_number
    add_index :business_processes, :archived_at
  end

  def self.down
    remove_index :business_processes, :archive_number
    remove_index :business_processes, :archived_at
    remove_column :business_processes, :archived_at
    remove_column :business_processes, :archive_number
    add_column :business_processes, :active, :boolean
  end
end
