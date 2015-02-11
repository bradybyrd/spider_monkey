class CreateTickets < ActiveRecord::Migration
  def self.up
    create_table :tickets do |t|
      t.string  :foreign_id,         :null => false
      t.string  :name,               :null => false
      t.string  :status,             :null => false, :default => "Unknown"
      t.string  :ticket_type,                        :default => "General"
      t.integer :project_server_id

      t.timestamps
    end
    add_index :tickets, :foreign_id
    add_index :tickets, :status
    add_index :tickets, :ticket_type
    add_index :tickets, :project_server_id
  end

  def self.down
    drop_table :tickets
  end
end
