class AddContactNumberToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :contact_number, :string
  end

  def self.down
    remove_column :users, :contact_number
  end
end
