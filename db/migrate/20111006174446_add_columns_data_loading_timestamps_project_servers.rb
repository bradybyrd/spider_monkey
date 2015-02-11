class AddColumnsDataLoadingTimestampsProjectServers < ActiveRecord::Migration
  def self.up
    add_column :project_servers, :data_loading_started_at, :datetime
    add_column :project_servers, :data_loading_completed_at, :datetime
  end

  def self.down
    remove_column :project_servers, :data_loading_started_at
    remove_column :project_servers, :data_loading_completed_at
  end
end