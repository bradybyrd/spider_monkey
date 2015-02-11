class AddLockedToPropertyValues < ActiveRecord::Migration
  def up
    add_column :property_values, :locked, :boolean, default: false, null: false
  end

  def down
    remove_column :property_values, :locked
  end
end
