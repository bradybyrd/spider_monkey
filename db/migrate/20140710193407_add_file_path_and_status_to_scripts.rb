class AddFilePathAndStatusToScripts < ActiveRecord::Migration
  def up
    add_column :scripts, :file_path, :string
    add_column :scripts, :aasm_state, :string
    Script.all.each do |temp|
      if temp.archived?
        temp.update_column(:aasm_state, 'archived_state')
      else
        temp.update_column(:aasm_state, 'released')
      end
    end
  end
  
  def down
    remove_column :scripts, :file_path
    remove_column :scripts, :aasm_state
  end
end
