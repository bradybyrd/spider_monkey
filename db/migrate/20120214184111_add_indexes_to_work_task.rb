class AddIndexesToWorkTask < ActiveRecord::Migration
  def self.up
    add_index :work_tasks, :name, :unique => true
    add_index :work_tasks, :position
    add_index :work_tasks, :active
  end

  def self.down
    #remove_index :work_tasks, :name
    #remove_index :work_tasks, :position
    #remove_index :work_tasks, :active
  end
end
