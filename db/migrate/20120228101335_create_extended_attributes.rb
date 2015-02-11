class CreateExtendedAttributes < ActiveRecord::Migration
  def self.up
    create_table :extended_attributes do |t|
      t.string :name
      t.string :value_text
      t.integer :value_holder_id
      t.string :value_holder_type
      t.boolean :active

      t.timestamps
    end
    add_index :extended_attributes, [:value_holder_id, :value_holder_type], :name => 'i_ex_at_va_ho_id_va_ho_ty'
  end

  def self.down
    drop_table :extended_attributes
  end
end
