class AddColumnsToScriptArguments26 < ActiveRecord::Migration
	
  def self.up
  	remove_column :script_arguments, :choices
  	
  	add_column :script_arguments, :position, :string
  	add_column :script_arguments, :is_required, :boolean
  	add_column :script_arguments, :external_resource, :string
  	add_column :script_arguments, :scripted_resource_id, :integer
  	add_column :script_arguments, :list_pairs, :string
    add_column :script_arguments, :created_by, :integer
    add_column :script_arguments, :updated_by, :integer  

    add_column :script_arguments, :argument_type, :string  

    self.add_default_hudson_script_arguments

    # change_column :script_arguments, :position, :string, :null => false
    change_column :script_arguments, :is_required, :boolean, :null => false
  end

  def self.down
  	add_column :script_arguments, :choices, :text

  	remove_column :script_arguments, :position
  	remove_column :script_arguments, :is_required
  	remove_column :script_arguments, :external_resource
  	remove_column :script_arguments, :scripted_resource_id
  	remove_column :script_arguments, :list_pairs
    remove_column :script_arguments, :argument_type
    remove_column :script_arguments, :created_by
    remove_column :script_arguments, :updated_by

  end

  def self.add_default_hudson_script_arguments
    if Script.all.size > 0
      Script.all.each do |script|
        script.arguments.each_with_index do |script_argument, index|
          index1 = index + 1       
          script_argument.update_attribute(:position, "A#{index1}:B#{index1}")
        end
      end      
    end
    ScriptArgument.update_all("is_required = #{RPMFALSE}") if ScriptArgument.all.size > 0         
  end

end
