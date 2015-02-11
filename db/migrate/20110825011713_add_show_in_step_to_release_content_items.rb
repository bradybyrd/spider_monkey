class AddShowInStepToReleaseContentItems < ActiveRecord::Migration
  def self.up
    add_column :release_content_items, :show_in_step, :boolean, :default => true
  end

  def self.down
    remove_column :release_content_items, :show_in_step
  end
end
