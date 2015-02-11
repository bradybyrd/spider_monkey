class AddActiveToRole < ActiveRecord::Migration
  def change
    add_column :roles, :active, :boolean, default: true
  end
end
