class AddIndexToRequestAasmState < ActiveRecord::Migration
  def self.up
    add_index :requests, :aasm_state
  end

  def self.down
    remove_index :requests, :aasm_state
  end
end
