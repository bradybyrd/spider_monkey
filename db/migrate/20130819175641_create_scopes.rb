class CreateScopes < ActiveRecord::Migration
  def change
    create_table :scopes do |t|
      t.integer :scopeable_id, :null => false
      t.string :scopeable_type, :null => false
      t.integer :scoped_id, :null => false
      t.string :scoped_type, :null => false

      t.timestamps
    end
    add_index :scopes, :scopeable_id, :name => 'I_SCOPE_SCOPEABLE_ID'
    add_index :scopes, :scopeable_type, :name => 'I_SCOPE_SCOPEABLE_TYPE'
    add_index :scopes, :scoped_id, :name => 'I_SCOPE_SCOPED_ID'
    add_index :scopes, :scoped_type, :name => 'I_SCOPE_SCOPED_TYPE'
    add_index :scopes, [:scopeable_id, :scoped_id], :unique => true, :name => 'I_SCOPE_SCOPEABLE_SCOPED'
  end
end
