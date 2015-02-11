class AddStrictToEnvironmentType < ActiveRecord::Migration
  def change
    add_column :environment_types, :strict, :boolean, :null => false, :default => false
    add_index :environment_types, :strict, :name => 'I_ENV_TYPES_STRICT'
  end
end
