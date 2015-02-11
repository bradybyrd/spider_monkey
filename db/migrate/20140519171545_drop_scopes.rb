class DropScopes < ActiveRecord::Migration
  def change
    drop_table :scopes
  end
end
