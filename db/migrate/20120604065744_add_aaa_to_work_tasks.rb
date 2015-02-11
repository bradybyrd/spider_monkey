class AddAaaToWorkTasks < ActiveRecord::Migration
  def self.up
    add_column :work_tasks, :archive_number, :string
    add_column :work_tasks, :archived_at, :datetime
    remove_index :work_tasks, :active
    remove_column :work_tasks, :active
    add_index :work_tasks, :archive_number
    add_index :work_tasks, :archived_at
  end

  def self.down
    remove_index :work_tasks, :archive_number
    remove_index :work_tasks, :archived_at
    add_column :work_tasks, :active ,:boolean
    add_index :work_tasks, :active
    remove_column :work_tasks, :archived_at
    remove_column :work_tasks, :archive_number
    
  end
end
