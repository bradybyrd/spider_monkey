class AddAasmStateToEnvironments < ActiveRecord::Migration
  def change
    add_column :environments, :aasm_state, :string, :null => false, :default => 'opened'
  end
end
