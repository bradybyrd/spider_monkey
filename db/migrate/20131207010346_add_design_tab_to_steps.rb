class AddDesignTabToSteps < ActiveRecord::Migration
  def change
    add_column :steps, :executor_data_entry, :boolean, :default => false, :null => false
    add_column :steps, :step_type, :string
    add_column :steps, :allow_unattended_promotion, :boolean, :default => false, :null => false
    add_column :steps, :execute_on_plan, :boolean, :default => false, :null => false
    add_column :steps, :protected_step, :boolean, :default => false, :null => false
    add_column :steps, :default_tab, :string

    rename_column :steps, :skip_email_notification, :suppress_notification
  end
end
