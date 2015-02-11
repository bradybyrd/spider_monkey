class AddVersionToSteps < ActiveRecord::Migration
  def self.up
    add_column :steps, :version_id, :integer
  end

  def self.down
    remove_column :steps, :version_id
  end
end
