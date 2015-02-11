class AddEnvironmentTypeToEnvironment < ActiveRecord::Migration
  def change
    add_column :environments, :environment_type_id, :integer
    add_index :environments, :environment_type_id, :name => 'I_ENV_ENV_TYP_ID'
  end
end
