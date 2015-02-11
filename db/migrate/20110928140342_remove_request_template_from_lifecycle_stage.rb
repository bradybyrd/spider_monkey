class RemoveRequestTemplateFromLifecycleStage < ActiveRecord::Migration
  def self.up
    remove_index :lifecycle_stages, :column => :request_template_id
    remove_column :lifecycle_stages, :request_template_id
  end

  def self.down
    add_column :lifecycle_stages, :request_template_id, :integer
  end
end

