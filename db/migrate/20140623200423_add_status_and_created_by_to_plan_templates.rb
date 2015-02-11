class AddStatusAndCreatedByToPlanTemplates < ActiveRecord::Migration
  def up
    add_column :plan_templates, :aasm_state, :string
    add_column :plan_templates, :created_by, :integer
    PlanTemplate.all.each do |temp|
      if temp.archived?
        temp.update_column(:aasm_state, 'archived_state')
      else
        temp.update_column(:aasm_state, 'released')
      end
    end
  end
  
  def down
    remove_column :plan_templates, :aasm_state
    remove_column :plan_templates, :created_by
  end
end
