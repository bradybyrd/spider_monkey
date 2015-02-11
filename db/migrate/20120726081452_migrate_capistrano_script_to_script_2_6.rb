class MigrateCapistranoScriptToScript26 < ActiveRecord::Migration
  def self.up
  	add_column :scripts, :old_cap_script_id, :integer
    add_column :script_arguments, :old_cap_script_argument_id, :integer

  	execute "INSERT INTO scripts (#{OracleAdapter ? "id, " : ""}old_cap_script_id, name, description, content, tag_id, integration_id, template_script_id,
  			template_script_type, automation_category , automation_type, is_active ,created_at, updated_at)
  			(SELECT #{OracleAdapter ? "scripts_seq.nextval, " : ""}id, name, description, content, tag_id, integration_id, template_script_id, template_script_type,
  			'General', 'Automation',#{RPMTRUE}, created_at, updated_at FROM capistrano_scripts)"

		execute "INSERT INTO script_arguments (#{OracleAdapter ? "id, " : ""}old_cap_script_argument_id, script_id, argument, name, argument_type, created_at, updated_at, is_private,
			position, is_required) (SELECT #{OracleAdapter ? "script_arguments_seq.nextval, " : ""}id, script_id, argument, name, 'in-text', created_at, updated_at, is_private, 'A1:B1', '#{RPMFALSE}'
			FROM capistrano_script_arguments)"

		# This methods will update the foriegn key column `script_id` in script_arguments table
		self.update_script_id_and_position

		# Remove unwanted columns
		remove_column :scripts, :old_cap_script_id
    remove_column :script_arguments, :old_cap_script_argument_id
  end

  def self.down
  	# raise IrreversibleMigration
  end

  # Additional methods to support the capistrano script migration to scripts table
  # This method will update foriegn key column present in script_arguments, steps and step_script-arguments table
  def self.update_script_id_and_position
  	# script_id_hash [old_script_id] = new_script_id
  	script_id_hash = {}
    script_argument_id_hash = {}

    # Store the old script id and new script id in the hash
  	Script.find_all_by_automation_category("General").each do |script|
			script_id_hash[script.old_cap_script_id] = script.id
  	end

    # Update the forign key script_id
  	ScriptArgument.all.each do |script_argument|
      if script_argument.old_cap_script_argument_id.present?
        script_argument_id_hash[script_argument.old_cap_script_argument_id] = script_argument.id
      end
      if script_id_hash[script_argument.script_id].present? && script_argument.old_cap_script_argument_id.present?
  		  script_argument.update_attribute(:script_id, script_id_hash[script_argument.script_id])
      end
  	end

    # Update the Position of all the script arguments
    Script.find_all_by_automation_category("General").each do |script|
      script.arguments.each_with_index do |script_argument, index|
        index1 = index + 1
        script_argument.update_attribute(:position, "A#{index1}:B#{index1}")
      end
    end

    # Update the foriegn key script_id in the steps table
    script_id_hash.each_pair do |k,v|
      execute "update steps set script_id = #{v}, script_type = 'General' where steps.script_id = #{k} and steps.script_type = 'CapistranoScript'"
    end

    # Update foriegn key script_argument_id in the step_script_arguments table
    script_argument_id_hash.each_pair do |k,v|
      execute "update step_script_arguments set script_argument_id = #{v}, script_argument_type = 'ScriptArgument' where step_script_arguments.script_argument_id = #{k} and step_script_arguments.script_argument_type='CapistranoScriptArgument'"
    end

    # Finally update script_argument_type column from CapistranoScriptAtgument to ScriptArgument
    StepScriptArgument.update_all( "script_argument_type = 'ScriptArgument'", "script_argument_type = 'CapistranoScriptArgument'" )
    Step.update_all("script_type = 'Hudson/Jenkins'", "script_type = 'HudsonScript'")

  end

end