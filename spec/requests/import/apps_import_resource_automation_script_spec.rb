require 'spec_helper'

describe '/v1/apps', import_export: true do
  before :each do
    @user = create(:user)
    create(:activity)
    create(:team, name: '[default]')
  end

  let(:base_url) { '/v1/apps' }
  let(:json_root) { :app }
  let(:xml_root) { 'app' }
  let(:import_root) { 'app_import/app' }
  let(:params) { {token: @user.api_key} }
  subject { response }

  describe 'import with app_import xml content' do
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }
    before(:all) { enable_automations }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      app_name = 'import_app_resource_automation_script'
      let(:added_app) { App.where(name: app_name).first || App.new }
      xml_file = File.open('spec/data/import_app_resource_automation_script.xml', 'r')
      xml_content = xml_file.read
      let(:imported_hash) { Hash.from_xml(xml_content) }

      let(:params) { xml_content }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_app.name) }

      it 'has imported resource scripts' do
        imported_resource_scripts.each do |xml_script|
          script = Script.find_by_name(xml_script['name'])
          expect(script.name).to eq(xml_script['name'])
          expect(script.automation_type).to eq(xml_script['automation_type'])
          expect(script.aasm_state).to eq(xml_script['aasm_state'])
          expect(script.content).to_not eq(xml_script['content'])
        end
      end

      it 'has imported project servers' do
        imported_project_servers.each do |xml_script|
          integration_server = ProjectServer.find_by_name(xml_script['name'])
          expect(integration_server.name).to eq(xml_script['name'])
        end
      end

    end
  end

  private

  def imported_resource_scripts
    imported_steps.flat_map do |request|
      request['resource_automation_script']
    end
  end

  def imported_project_servers
    imported_resource_scripts.flat_map do |request|
      request['project_server']
    end
  end

  def imported_steps
    imported_requests.flat_map do |request|
      request['steps']
    end
  end

  def imported_requests
    imported_hash['app_import']['app']['requests_for_export_with_automations']
  end

end
