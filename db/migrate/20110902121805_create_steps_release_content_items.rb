class CreateStepsReleaseContentItems < ActiveRecord::Migration
  def self.up
    create_table :steps_release_content_items do |t|
      t.integer :step_id
      t.integer :release_content_item_id
      t.timestamps
    end
  end

  def self.down
    drop_table :steps_release_content_items
  end
end
