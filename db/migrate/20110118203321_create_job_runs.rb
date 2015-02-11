################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateJobRuns < ActiveRecord::Migration
  def self.up
    create_table :job_runs do |t|
      t.string :job_type
      t.string :status
      t.integer :run_key
      t.integer :delayed_job_id
      t.integer :user_id
      t.integer :process_id
      t.integer :automation_id
      t.integer :step_id
      t.timestamp :started_at
      t.timestamp :finished_at
      t.string :results_path
      t.text :stdout
      t.text :stderr
      t.timestamps
    end
    add_index :job_runs, :run_key
  end

  def self.down
    drop_table :job_runs
  end
end
