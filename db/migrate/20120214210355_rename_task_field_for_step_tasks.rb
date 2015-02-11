class RenameTaskFieldForStepTasks < ActiveRecord::Migration
  def self.up
    remove_index :steps, :task_id
    rename_column :steps, :task_id, :work_task_id 
    rename_column :steps, :frozen_task, :frozen_work_task
    add_index :steps, :work_task_id
    
    remove_index :property_tasks, :task_id
    rename_column :property_tasks, :task_id, :work_task_id 
    add_index :property_tasks, :work_task_id
    rename_table :property_tasks, :property_work_tasks
  end

  def self.down
    remove_index :steps, :work_task_id
    rename_column :steps, :work_task_id, :task_id 
    rename_column :steps, :frozen_work_task, :frozen_task
    add_index :steps, :task_id
    
    rename_table :property_work_tasks, :property_tasks
    remove_index :property_tasks, :work_task_id
    rename_column :property_tasks, :work_task_id, :task_id 
    add_index :property_tasks, :task_id
  end
end
