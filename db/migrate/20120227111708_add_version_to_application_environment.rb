class AddVersionToApplicationEnvironment < ActiveRecord::Migration
  def self.up
    add_column :application_environments, :version_id, :integer
  end

  def self.down
    remove_column :application_environments, :version_id
  end
end
