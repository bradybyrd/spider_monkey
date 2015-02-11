class AddColumnsToScripts26 < ActiveRecord::Migration

  def self.up
    remove_column :scripts, :script_type
    add_column :scripts, :authentication, :string
  	add_column :scripts, :automation_category, :string
  	add_column :scripts, :automation_type, :string
  	add_column :scripts, :is_active, :boolean
    add_column :scripts, :created_by, :integer
    add_column :scripts, :updated_by, :integer

    self.add_default_values_for_hudson_script

    change_column :scripts, :automation_category, :string, :null => false
    change_column :scripts, :automation_type, :string, :null => false
    change_column :scripts, :is_active, :boolean, :null => false
  end

  def self.down
    add_column :scripts, :script_type
    remove_column :scripts, :authentication
  	remove_column :scripts, :automation_category
  	remove_column :scripts, :automation_type
    remove_column :scripts, :is_active
    remove_column :scripts, :created_by
    remove_column :scripts, :updated_by
  end

  def self.add_default_values_for_hudson_script
    if Script.all.size > 0
      Script.update_all("automation_category = 'Hudson/Jenkins', automation_type = 'Automation',
       is_active = '#{RPMTRUE}'")      
    end
  end

end