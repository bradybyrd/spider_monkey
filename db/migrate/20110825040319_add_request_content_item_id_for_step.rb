class AddRequestContentItemIdForStep < ActiveRecord::Migration
  def self.up
    add_column :steps, :release_content_item_id, :integer
    add_column :steps, :custom_ticket_id, :integer
  end

  def self.down
    remove_column :steps, :release_content_item_id
    remove_column :steps, :custom_ticket_id
  end
end
