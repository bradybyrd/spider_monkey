class AddMissingIndexesAgain < ActiveRecord::Migration
  def change
    add_index :activity_attributes, [:id, :type]
    add_index :users, [:id, :type]
  end
end
