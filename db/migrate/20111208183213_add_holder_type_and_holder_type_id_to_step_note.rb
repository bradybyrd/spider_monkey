class AddHolderTypeAndHolderTypeIdToStepNote < ActiveRecord::Migration
  def self.up
    add_column :notes, :holder_type, :string
    add_column :notes, :holder_type_id, :string
  end

  def self.down
    remove_column :notes, :holder_type
    remove_column :notes, :holder_type_id
  end
end
