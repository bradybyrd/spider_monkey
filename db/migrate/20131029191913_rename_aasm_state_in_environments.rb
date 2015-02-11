class RenameAasmStateInEnvironments < ActiveRecord::Migration
  def change
    rename_column :environments, :aasm_state, :deployment_policy
  end
end
