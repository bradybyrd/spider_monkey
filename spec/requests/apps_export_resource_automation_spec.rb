require 'spec_helper'

describe '/v1/apps', import_export: true do
  before :all do
    @user = create(:user)
  end

  let(:base_url) { '/v1/apps' }
  let(:json_root) { :app }
  let(:xml_root) { 'app' }
  let(:import_root) { 'app_import/app' }
  let(:params) { {token: @user.api_key} }

  describe 'export /v1/apps/[id] with optional request template resource automations' do
    before(:each) { create_app_with_automation_script }
    let (:url) { app_export_url_including(:req_templates, :automations) }

    it "successful request", type: :xml do
      xget url
      expect(response.body).to have_automation_script('name').with_text(@resource_script.name)
      expect(response.body).to have_automation_script('description').with_text(@resource_script.description)
      expect(response.body).to have_automation_script('aasm-state').with_text(@resource_script.aasm_state)
      expect(response.body).to have_automation_script('content').with_text(@resource_script.content)
      expect(response.body).to have_automation_script('automation-type').with_text(@resource_script.automation_type)
      expect(response.body).to have_project_server('name').with_text(@resource_script.project_server.name)
    end
  end

  describe 'export /v1/apps/[id] with optional request template resource automations in draft state are not exported' do
    before(:each) { create_app_with_automation_script_in_draft }
    let (:url) { app_export_url_including(:req_templates, :automations) }

    it "successful request", type: :xml do
      xget url
      expect(response.body).not_to have_automation_script
    end
  end


  def have_automation_script(xpath="")
    if xpath.present?
      xpath = "/#{xpath}"
    end
    have_xpath("app/requests-for-export-with-automations/requests-for-export-with-automation[1]/steps/step[1]/resource-automation-script/resource-automation-script[1]#{xpath}")
  end

  def have_project_server(xpath="")
    if xpath.present?
      xpath = "/#{xpath}"
    end
    have_xpath("app/requests-for-export-with-automations/requests-for-export-with-automation[1]/steps/step[1]/resource-automation-script/resource-automation-script[1]/project-server#{xpath}")
  end

  def app_export_url_including(*optional_components)
    optional_components = optional_components.join(',')
    "#{base_url}/#{@app.id}?token=#{@user.api_key}&export_xml=true&optional_components=[#{optional_components}]"
  end

  def create_app_with_automation_script
    @project_server = create(:project_server)
    @resource_script = create(:resource_automation_script,integration_id: @project_server.id)
    create_automation_script(@resource_script)
  end

  def create_app_with_automation_script_in_draft
    @resource_script = create(:resource_automation_script, aasm_state: "draft")
     create_automation_script(@resource_script)
  end

  def create_automation_script(resource_script)
    step_with_script = create(:step_with_script)
    @script = step_with_script.script
    @argument = @script.arguments.first
    @argument.external_resource = resource_script.unique_identifier
    @argument.save!
    request_with_automated_steps = create(:request)
    create(:request_template, request: request_with_automated_steps)
    @app = create(:app)
    @app.requests << request_with_automated_steps
    @app.requests.first.request_template.request.steps << step_with_script
  end

end
