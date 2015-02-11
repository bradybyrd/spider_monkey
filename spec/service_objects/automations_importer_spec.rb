require 'spec_helper'

describe AutomationsImporter, import_export: true do
  describe '#import' do
    context 'with automations, and without automations enabled' do
      it 'throws an error with helpful message and does not import the script' do
        enable_automations(false)
        automation_for_import = build_automation_script_for_export(
          name: 'Another Script',
          description: 'Something',
          aasm_state: 'draft',
          content: 'Great content',
          automation_type: 'Manual',
          automation_category: 'General'
        )

        expect{ AutomationsImporter.new([automation_for_import]).import }.
          to raise_error(AutomationsImporter::ImportError)
        imported = Script.find_by_name(automation_for_import[:name])
        expect(imported).to be_nil
      end
    end

    context 'without any automations, and without automations enabled' do
      it 'does not throw an error message' do
        enable_automations(false)

        expect{ AutomationsImporter.new([]).import }.
          not_to raise_error
      end
    end

    context 'automation enabled and script with matching name exists' do
      it 'updates the existing script with the exported automation' do
        enable_automations
        existing = create(:general_script)
        automation_for_import = build_automation_script_for_export(
          name: existing.name,
          description: 'Something',
          aasm_state: 'draft',
          content: existing.content,
          automation_type: 'Manual',
          automation_category: 'General'
        )

        AutomationsImporter.new([automation_for_import]).import

        existing.reload
        expect(existing.name).to eq automation_for_import[:name]
        expect(existing.description).to eq automation_for_import[:description]
        expect(existing.aasm_state).to eq automation_for_import[:aasm_state]
        expect(existing.content).to eq automation_for_import[:content]
        expect(existing.automation_type).
          to eq automation_for_import[:automation_type]
        expect(existing.automation_category).
          to eq automation_for_import[:automation_category]
      end
    end

    context 'automation enabled and no script exists with matching name' do
      it 'creates a new script' do
        enable_automations
        existing_script = create(:general_script, name: 'My Script')
        automation_for_import = build_automation_script_for_export(
          name: 'Another Script',
          description: 'Something',
          aasm_state: 'draft',
          content: 'Great content',
          automation_type: 'Manual',
          automation_category: 'General'
        )

        AutomationsImporter.new([automation_for_import]).import

        imported = Script.find_by_name(automation_for_import[:name])
        expect(imported.name).to eq automation_for_import[:name]
        expect(imported.description).to eq automation_for_import[:description]
        expect(imported.aasm_state).to eq automation_for_import[:aasm_state]
        expect(imported.content).to eq automation_for_import[:content]
        expect(imported.automation_type).
          to eq automation_for_import[:automation_type]
        expect(imported.automation_category).
          to eq automation_for_import[:automation_category]
      end
    end

    context 'project server is included in the automation script' do
      it 'imports the project server' do
        enable_automations
        project_server_for_import = {
          server_name_id: 5,
          details: 'details',
          ip: '1.1.1.1',
          name: 'My Server',
          password: 'password',
          port: 8000,
          server_url: 'myurl.url',
          username: 'my_username'
        }
        automation_for_import = build_automation_script_for_export(
          project_server: project_server_for_import
        )

        AutomationsImporter.new([automation_for_import]).import

        server = Script.find_by_name(automation_for_import[:name]).project_server
        expect(server.name).to eq project_server_for_import[:name]
        expect(server.details).to eq project_server_for_import[:details]
        expect(server.ip).to eq project_server_for_import[:ip]
        expect(server.port).to eq project_server_for_import[:port]
        expect(server.password).to eq project_server_for_import[:password]
        expect(server.server_url).to eq project_server_for_import[:server_url]
        expect(server.username).to eq project_server_for_import[:username]
        expect(server.server_name_id).
          to eq project_server_for_import[:server_name_id]
      end
    end
  end

  def build_automation_script_for_export(options={})
    {
      name: 'Another Script',
      description: 'Something',
      aasm_state: 'draft',
      content: 'Great content',
      automation_type: 'Manual',
      automation_category: 'General',
      project_server: {}
    }.merge(options)
  end
end
