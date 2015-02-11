class AddEnvironmentsNamesToOccurrence < ActiveRecord::Migration
  def change
    add_column :deployment_window_occurrences, :environment_names, :text unless column_exists? :deployment_window_occurrences, :environment_names, :text
  end
end
