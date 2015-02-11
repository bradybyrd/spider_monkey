class CreateRuns < ActiveRecord::Migration
  def self.up
    create_table :runs do |t|
      t.string :name, :nil => false
      t.datetime :start_at
      t.datetime :end_at
      t.integer :duration
      t.string :description
      t.integer :requestor_id, :nil => false
      t.integer :owner_id, :nil => false
      t.integer :lifecycle_id, :nil => false
      t.integer :lifecycle_stage_id, :nil => false
      t.string :aasm_state, :nil => false, :default => 'created'

      t.timestamps
    end
    
    add_index :runs, :name
    add_index :runs, :start_at
    add_index :runs, :end_at
    add_index :runs, :requestor_id
    add_index :runs, :owner_id
    add_index :runs, :lifecycle_id
    add_index :runs, :lifecycle_stage_id
    
  end

  def self.down
    drop_table :runs
  end
end
