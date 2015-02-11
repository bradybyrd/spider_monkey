class AddAppIdToTickets < ActiveRecord::Migration
  def self.up
    add_column :tickets, :app_id, :integer
  end

  def self.down
    remove_column :tickets, :app_id
  end
end
