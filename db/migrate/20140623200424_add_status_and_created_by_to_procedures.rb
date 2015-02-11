class AddStatusAndCreatedByToProcedures < ActiveRecord::Migration
  def up
    add_column :procedures, :aasm_state, :string
    add_column :procedures, :created_by, :integer
    Procedure.all.each do |temp|
      if temp.archived?
        temp.update_column(:aasm_state, 'archived_state')
      else
        temp.update_column(:aasm_state, 'released')
      end
    end
  end
  
  def down
    remove_column :procedures, :aasm_state
    remove_column :procedures, :created_by
  end
end
