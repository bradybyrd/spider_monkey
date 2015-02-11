class CreateStepReferences < ActiveRecord::Migration
  def change
    create_table :step_references do |t|
      t.integer :step_id
      t.integer :reference_id
      t.integer :owner_object_id
      t.string :owner_object_type
      t.timestamps
    end
  end
end
