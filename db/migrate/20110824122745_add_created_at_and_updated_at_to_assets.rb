class AddCreatedAtAndUpdatedAtToAssets < ActiveRecord::Migration
  def self.up
    add_column :assets, :created_at, :datetime
    add_column :assets, :updated_at, :datetime
  end

  def self.down
    remove_column :assets, :created_at
    remove_column :assets, :updated_at
  end
end
