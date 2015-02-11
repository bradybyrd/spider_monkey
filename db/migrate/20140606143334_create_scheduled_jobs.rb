class CreateScheduledJobs < ActiveRecord::Migration
  def change
    create_table :scheduled_jobs do |t|
      t.integer :resource_id, :null => false
      t.string :resource_type, :null => false
      t.integer :owner_id, :null => false
      t.string :status, :null => false, :default => 'Scheduled'
      t.datetime :planned_at, :null => false
      t.text :log, :null => false

      t.timestamps
    end

    add_index :scheduled_jobs, :resource_id, :name => 'I_SCH_JOB_RES_ID'
    add_index :scheduled_jobs, :resource_type, :name => 'I_SCH_JOB_RES_TYPE'
    add_index :scheduled_jobs, :owner_id, :name => 'I_SCH_JOB_OWNER_ID'
    add_index :scheduled_jobs, :status, :name => 'I_SCH_JOB_STATUS'
    add_index :scheduled_jobs, :planned_at, :name => 'I_SCH_JOB_PLAN_DT'
  end
end
