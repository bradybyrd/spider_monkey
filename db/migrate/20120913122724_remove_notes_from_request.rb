class RemoveNotesFromRequest < ActiveRecord::Migration
  def self.up
  	remove_column :requests, :notes
  end

  def self.down
  	add_column :requests, :notes, :text
  end
end
