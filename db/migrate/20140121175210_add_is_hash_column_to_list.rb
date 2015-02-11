class AddIsHashColumnToList < ActiveRecord::Migration
  def change
    add_column :lists, :is_hash, :boolean, null: false, default: false
  end
end
