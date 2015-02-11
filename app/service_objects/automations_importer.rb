class AutomationsImporter
  class ImportError < StandardError; end

  def initialize(automation_scripts)
    @automation_scripts = automation_scripts
  end

  def import
    if automation_scripts.present? && !GlobalSettings.automation_enabled?
      raise ImportError, 'Automations must be enabled in order to import automation scripts'
    else
      import_automation_scripts
    end
  end

  private

  attr_reader :automation_scripts

  def import_automation_scripts
    automation_scripts.each do |automation_script|
      automation_script = automation_script.with_indifferent_access
      project_server = automation_script[:project_server]
      script = import_automation_script(automation_script)
      import_ssh_integration_server(project_server, script,automation_script)
    end
  end

  def import_automation_script(automation_script)
    script = Script.where(name: automation_script[:name]).first_or_initialize
    automation_script.delete 'project_server'
    script.attributes = automation_script
    script.is_import = true
    script.save!
    script
  end

  def import_ssh_integration_server(project_server, script,automation_script)
    if project_server[:name]
      integration_server = ProjectServer.
        where(name: project_server[:name]).
        first_or_initialize
      integration_server.attributes = project_server
      integration_server.save!
      script.project_server = integration_server
      original_data = automation_script[:content]
      script_text = "\n# Integration server not found #"
      script_text = integration_server.add_update_integration_values(original_data, true) unless integration_server.nil?
      script.content = script_text
      script.save!
    end
  end
end
