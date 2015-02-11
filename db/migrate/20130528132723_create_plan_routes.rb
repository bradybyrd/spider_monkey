class CreatePlanRoutes < ActiveRecord::Migration
  def change
    create_table :plan_routes do |t|
      t.integer :plan_id, :null => false
      t.integer :route_id, :null => false

      t.timestamps
    end
    add_index :plan_routes, :plan_id, :name => 'I_PLAN_ROUTE_PLAN_ID'
    add_index :plan_routes, :route_id, :name => 'I_PLAN_ROUTE_ROUTE_ID'
  end
end
