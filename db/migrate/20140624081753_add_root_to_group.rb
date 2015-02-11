class AddRootToGroup < ActiveRecord::Migration
  def change
    add_column :groups, :root, :boolean, default: false
  end
end
