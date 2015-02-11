class AddMissingIndexesAgain < ActiveRecord::Migration
  def change
    add_index :satpms, [:script_argument_id, :script_argument_type]
    add_index :satpms, [:value_holder_id, :value_holder_type]
    add_index :requests, :origin_request_template_id
    add_index :step_execution_conditions, :runtime_phase_id
    add_index :step_execution_conditions, :step_id
    add_index :assigned_apps, [:team_id, :user_id]
    add_index :assigned_apps, [:app_id, :team_id]
    add_index :assigned_apps, :team_id
    add_index :deployment_window_events, :occurrence_id
    add_index :activity_attributes, [:id, :type]
    add_index :users, [:id, :type]
  end
end
