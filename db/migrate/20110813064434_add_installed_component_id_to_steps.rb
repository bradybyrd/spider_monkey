class AddInstalledComponentIdToSteps < ActiveRecord::Migration
  def self.up
    add_column :steps, :installed_component_id, :integer
  end

  def self.down
    remove_column :steps, :installed_component_id
  end
end
