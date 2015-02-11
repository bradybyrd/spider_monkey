class CreateTablePlanEnvAppDates < ActiveRecord::Migration
  def self.up
    create_table :plan_env_app_dates do |t| 
      t.integer  :plan_id, :null => false 
      t.integer  :plan_template_id, :null => false 
      t.integer  :environment_id, :null => false 
      t.integer  :app_id, :null => false 
      t.date     :planned_start 
      t.date     :planned_complete
  
      t.datetime  :created_at, :null => false 
      t.datetime  :updated_at 
      t.integer   :created_by, :null => false 
      t.integer   :updated_by 
    end
  end

  def self.down
    drop_table :plan_env_app_dates
  end
end
