class AddStepIdToActivityLog < ActiveRecord::Migration
  def self.up
    add_column :activity_logs, :step_id, :integer
    add_column :activity_logs, :type, :string
  end

  def self.down
    remove_column :activity_logs, :step_id
    remove_column :activity_logs, :type
  end
end
