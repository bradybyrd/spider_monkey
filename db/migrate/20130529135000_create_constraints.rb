class CreateConstraints < ActiveRecord::Migration
  def change
    create_table :constraints do |t|
      t.integer :constrainable_id, :null => true
      t.string :constrainable_type, :null => true
      t.integer :governable_id, :null => true
      t.string :governable_type, :null => true
      t.boolean :active, :null => true, :default => true

      t.timestamps
    end
    add_index :constraints, :constrainable_id, :name => 'I_CONSTRAINT_CONST_ID'
    add_index :constraints, :constrainable_type, :name => 'I_CONSTRAINT_CONST_TYPE'
    add_index :constraints, :governable_id, :name => 'I_CONSTRAINT_GOV_ID'
    add_index :constraints, :governable_type, :name => 'I_CONSTRAINT_GOV_TYPE'
    add_index :constraints, :active, :name => 'I_CONSTRAINT_ACTIVE'
    add_index :constraints, [:constrainable_id, :governable_id], :unique => true, :name => 'I_CONSTRAINT_CONST_GOV'
  end
end
