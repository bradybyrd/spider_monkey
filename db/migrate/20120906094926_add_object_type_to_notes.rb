class AddObjectTypeToNotes < ActiveRecord::Migration

  def self.up
  	add_column :notes, :object_type, :string
  	Note.update_all ["object_type=?", "Step"]
  end

  def self.down
  	remove_column :notes, :object_type
  end
end
