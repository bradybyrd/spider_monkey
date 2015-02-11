class AddStatusAndCreatedByToRequestTemplates < ActiveRecord::Migration
  def up
    add_column :request_templates, :aasm_state, :string
    add_column :request_templates, :created_by, :integer
    RequestTemplate.all.each do |temp|
      if temp.archived?
        temp.update_column(:aasm_state, 'archived_state')
      else
        temp.update_column(:aasm_state, 'released')
      end
    end
  end
  
  def down
    remove_column :request_templates, :aasm_state
    remove_column :request_templates, :created_by
  end
end
