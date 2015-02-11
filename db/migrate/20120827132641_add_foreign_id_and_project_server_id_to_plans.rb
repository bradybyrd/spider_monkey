class AddForeignIdAndProjectServerIdToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :foreign_id, :string
    add_column :plans, :project_server_id, :integer
  end
end
