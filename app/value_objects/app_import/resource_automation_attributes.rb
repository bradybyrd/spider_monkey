module AppImport
  class ResourceAutomationAttributes
    attr_reader :xml_hash

    def initialize(xml_hash)
      @xml_hash = xml_hash
    end

    def import_app_request
      xml_hash.each do |key|
        @script = Script.where(name: key['name']).first_or_create
        @script.update_attributes(resource_script_params(key))
        @script.update_attribute( :aasm_state, key['aasm_state'] )
        update_integration_server(@script,key)
      end
    end

    private

    def resource_script_params(script_hash)
      {
          description: script_hash['description'],
          content: script_hash['content'],
          automation_category: script_hash['automation_category'],
          render_as: script_hash['render_as'],
          maps_to: script_hash['maps_to'],
          template_script_type: script_hash['template_script_type'],
          automation_type: script_hash['automation_type'],
          unique_identifier: script_hash['unique_identifier']
      }
    end

    def project_server_params(script_hash)
      {
          password: script_hash['password'],
          port: script_hash['port'],
          server_url: script_hash['server_url'],
          username: script_hash['username'],
          details: script_hash['details'],
          ip: script_hash['ip'],
          server_name_id: script_hash['server_name_id']
      }
    end

    def update_integration_server(script,script_hash)
      if script_hash['project_server']
        @project_server = ProjectServer.where(name: script_hash['project_server']['name']).first_or_initialize
        @project_server.update_attributes(project_server_params(script_hash['project_server']))
        script.project_server = @project_server
        original_data = script_hash['content']
        script_text = "\n# Integration server not found #"
        script_text = @project_server.add_update_integration_values(original_data, true) unless @project_server.nil?
        script.content = script_text
        script.save!
      end
    end
  end

end
