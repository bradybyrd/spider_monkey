class DeleteDelayedJobIdFromJobRun < ActiveRecord::Migration
  def up
    remove_column :job_runs, :delayed_job_id
  end

  def down
    add_column :job_runs, :delayed_job_id, :integer
  end
end
