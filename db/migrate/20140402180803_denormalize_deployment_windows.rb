class DenormalizeDeploymentWindows < ActiveRecord::Migration
  def change
    add_column :deployment_window_events, :name, :string
    add_column :deployment_window_events, :environment_names, :text
    add_column :deployment_window_events, :behavior, :string
    add_column :deployment_window_events, :requests_count, :integer, default: 0

    add_column :deployment_window_series, :environment_names, :text
    add_column :deployment_window_series, :requests_count, :integer, default: 0
  end
end
