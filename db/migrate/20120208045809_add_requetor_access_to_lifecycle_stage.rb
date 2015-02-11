class AddRequetorAccessToLifecycleStage < ActiveRecord::Migration
  def self.up
    add_column  :lifecycle_stages, :requestor_access, :boolean , :default => true
  end

  def self.down
    remove_column :lifecycle_stages, :requestor_access
  end
end

