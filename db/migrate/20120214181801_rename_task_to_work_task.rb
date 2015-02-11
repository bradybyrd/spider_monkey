class RenameTaskToWorkTask < ActiveRecord::Migration
  def self.up
    rename_table :tasks, :work_tasks
  end

  def self.down
    rename_table :work_tasks, :tasks
  end
end
