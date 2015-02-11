class AddIndexesToAssets < ActiveRecord::Migration
  def change
    add_index :assets, :owner_type
    add_index :assets, :user_id
  end
end
