class CreateLinkedItems < ActiveRecord::Migration
  def self.up
    create_table :linked_items do |t|
      t.string  :name
      t.integer :source_holder_id,    :null => false
      t.string  :source_holder_type,  :null => false
      t.integer :target_holder_id,    :null => false
      t.string  :target_holder_type,  :null => false
      t.integer :rule_id

      t.timestamps
    end
    add_index :linked_items, :source_holder_id
    add_index :linked_items, :target_holder_id
    add_index :linked_items, [:source_holder_id, :source_holder_type]
    add_index :linked_items, [:target_holder_id, :target_holder_type]
  end

  def self.down
    drop_table :linked_items
  end
end
