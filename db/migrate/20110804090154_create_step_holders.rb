class CreateStepHolders < ActiveRecord::Migration
  def self.up
    create_table :step_holders do |t|
      t.integer :step_id
      t.integer :change_request_id
      t.integer :request_id
      t.timestamps
    end    
  end

  def self.down
    drop_table :step_holders
  end
end
