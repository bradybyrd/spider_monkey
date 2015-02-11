class AddStatusAndCreatedByToDeploymentWindowSeries < ActiveRecord::Migration
  def up
    add_column :deployment_window_series, :aasm_state, :string
    add_column :deployment_window_series, :created_by, :integer
    DeploymentWindow::Series.all.each do |temp|
      if temp.archived?
        temp.update_column(:aasm_state, 'archived_state')
      else
        temp.update_column(:aasm_state, 'released')
      end
    end
  end
  
  def down
    remove_column :deployment_window_series, :aasm_state
    remove_column :deployment_window_series, :created_by
  end
end
