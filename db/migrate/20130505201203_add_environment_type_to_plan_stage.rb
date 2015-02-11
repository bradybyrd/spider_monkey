class AddEnvironmentTypeToPlanStage < ActiveRecord::Migration
  def change
    add_column :plan_stages, :environment_type_id, :integer
    add_index :plan_stages, :environment_type_id, :name => 'I_PLA_STA_ENV_TYP_ID'
  end
end
