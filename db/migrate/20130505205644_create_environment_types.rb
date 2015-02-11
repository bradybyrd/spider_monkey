class CreateEnvironmentTypes < ActiveRecord::Migration
  def change
    create_table :environment_types do |t|
      t.string :name, :null => false
      t.string :description
      t.integer :position, :null => false, :default => 0

      t.timestamps
    end
    add_index :environment_types, :name, :name => 'I_ENV_TYP_NAM', :unique => true
    add_index :environment_types, :position, :name => 'I_ENV_TYP_POS'
  end
end
