class AddFrequencyToSeries < ActiveRecord::Migration
  def change
    add_column :deployment_window_series, :frequency_name, :string
    add_column :deployment_window_series, :frequency_description, :string
    add_index  :deployment_window_series, :frequency_name, name: 'DW_SERIES_FREQUENCY'
    DeploymentWindow::Series.where(recurrent: true).find_each do |series|
      series.update_attributes(frequency_description: series.schedule.rrules.first.to_s,
                               frequency_name: series.schedule.rrules.first.class.name.match(/Daily|Weekly|Monthly/)[0] || '-')
    end
  end
end
