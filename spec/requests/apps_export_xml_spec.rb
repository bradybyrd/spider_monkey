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
  subject { response }

  describe 'export /v1/apps/[id] with no optional objects' do
    before(:each) do
      @app = create(:app,:with_installed_component)
      @business_process = create(:business_process, apps: [@app])
      @server = create(:server)
      @app.environments.each do |env|
        env.server_ids = [@server.id]
        env.save
      end
      @env = @app.environments.first
      @route = create(:route, app: @app)
      @route_gate = create(:route_gate, route: @route)
      @route_archived = create(:route, app: @app)
      @route_archived.toggle_archive
    end
    let (:url) { "#{base_url}/#{@app.id}?token=#{@user.api_key}&export_xml=true" }

    it_behaves_like "successful request", type: :xml do
      subject { response.body }

      it { should have_xpath('app/name').with_text(@app.name) }
      it { should have_xpath('app/brpm_version').with_text(ApplicationController.helpers.get_version_from_file) }

      it { should have_xpath("app/active-routes/active-route[1]/name").with_text(@route.name) }
      it { should_not have_xpath("app/active-routes/active-route[2]/name").with_text(@route_archived.name) }
      it { should have_xpath("app/active-routes/active-route[1]/route-type").with_text(@route.route_type) }
      it { should have_xpath("app/active-routes/active-route[1]/description").with_text(@route.description) }
      it { should have_xpath("app/active-routes/active-route[1]/route-gates/route-gate[1]/position").with_text(@route_gate.position) }
      it { should have_xpath("app/active-routes/active-route[1]/route-gates/route-gate[1]/environment/name").with_text(@route_gate.environment.name) }

      it { should have_xpath("app/components/component[1]/name").with_text(@app.components.first.name) }
      it { should have_xpath("app/environments/environment[1]/name").with_text(@env.name) }
      it { should_not have_xpath("app/environments/environment[1]/environment-servers") }
      it { should have_xpath("app/installed-components/installed-component[1]/application-environment/name").with_text(@env.name)
      }
      it { should have_xpath('app/active-business-processes/active-business-process[1]/name').with_text(@business_process.name) }
      it { should have_xpath('app/active-business-processes/active-business-process[1]/label-color').with_text(@business_process.label_color) }
    end
  end

  describe 'export /v1/apps/[id] with optional server objects' do
    before(:each) do
      @app = create(:app,:with_installed_component)
      @active_property = create(:property, active: true)
      @inactive_property = create(:property, active: false)
      @server = create(:server, properties: [@active_property, @inactive_property])
      @app.environments.each do |env|
        env.server_ids = [@server.id]
        env.save
      end
    end
    let (:url) { app_export_url_including(:servers) }

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('app/name').with_text(@app.name) }
      it { should have_xpath("app/environments/environment[1]/active-environment-servers/active-environment-server[1]/server/name").with_text(@server.name) }
      it { should have_xpath("app/environments/environment[1]/active-environment-servers/active-environment-server[1]/server/properties/property[1]/name").with_text(@active_property.name) }
      it { should_not have_xpath("app/environments/environment[1]/active-environment-servers/active-environment-server[1]/server/properties/property[2]") }
    end
  end

  describe 'export /v1/apps/[id] with optional request template automations' do
    before(:each) { create_app_with_automation_script }
    let (:url) { app_export_url_including(:req_templates, :automations) }

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_automation_script('name').with_text(@script.name) }
      it { should have_automation_script('description').with_text(@script.description) }
      it { should have_automation_script('aasm-state').with_text(@script.aasm_state) }
      it { should have_automation_script('content').with_text(@script.content) }
      it { should have_automation_script('automation-type').with_text(@script.automation_type) }
    end
  end

  describe 'export /v1/apps/[id] without optional automations' do
    before(:each) { create_app_with_automation_script }
    let (:url) { app_export_url_including(:req_templates) }

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should_not have_automation_script }
    end
  end


  describe 'export /v1/apps/[id] with version tags' do
    before(:each) do
      @vt = create(:version_tag)
      @app = @vt.app
    end

    let (:url) { "#{base_url}/#{@app.id}?token=#{@user.api_key}&export_xml=true" }
      it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('app/name').with_text(@app.name) }
      it { should have_xpath("app/version-tags/version-tag[1]/name").with_text(@vt.name) }
    end
  end

  describe 'export /v1/apps/[id] with requests' do
    before(:each) do
      @request_template = create(:request_template, name: "RecurringRequest", request: create(:request_with_app))
      @app = @request_template.apps.first
    end

    let (:url) { app_export_url_including(:req_templates) }

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('app/name').with_text(@app.name) }
      it { should have_xpath("app/requests-for-export/requests-for-export[1]/request-template/name").with_text(@request_template.name) }
      it { should have_xpath("app/requests-for-export/requests-for-export[1]/name").with_text(@request_template.request.name) }
    end
  end

  describe 'export /v1/apps/[id] with requests/request templates which are not in draft' do
    before(:each) do
      @request_template1 = create(:request_template, name: "RecurringRequest", request: create(:request_with_app))
      @request_template2 = create(:request_template, name: "RecurringRequest123",aasm_state:'draft', request: create(:request_with_app))
      @app = @request_template1.apps.first
    end

    let (:url) { app_export_url_including(:req_templates) }

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('app/name').with_text(@app.name) }
      it { should have_request_template('name').with_text(@request_template1.name) }
      it { should have_request('name').with_text(@request_template1.request.name) }
      it { should_not have_request_template('name').with_text(@request_template2.name) }
      it { should_not have_request('name').with_text(@request_template2.request.name) }
    end
  end

  describe 'export /v1/apps/[id] with requests/steps' do
    before(:each) do
      @request_template = create(:request_template, name: "RecurringRequest", request: create(:request_with_app))
      @runtime_phase = create(:runtime_phase)
      @step = create(:step_with_script, request: @request_template.request, phase: @runtime_phase.phase, runtime_phase: @runtime_phase)
      @app = @request_template.apps.first
    end

    let (:url) { app_export_url_including(:req_templates) }

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('app/name').with_text(@app.name) }
      it { should have_xpath("app/requests-for-export/requests-for-export[1]/request-template/name").with_text(@request_template.name) }
      it { should have_xpath("app/requests-for-export/requests-for-export[1]/name").with_text(@request_template.request.name) }
      it { should have_xpath("app/requests-for-export/requests-for-export[1]/steps/step[1]/name").with_text(@step.name) }

      context 'has phases and runtime phases' do
        it { should have_xpath("app/requests-for-export/requests-for-export[1]/steps/step[1]/phase/name").with_text(@runtime_phase.phase.name) }
        it { should have_xpath("app/requests-for-export/requests-for-export[1]/steps/step[1]/phase/position").with_text(@runtime_phase.phase.position) }
        it { should_not have_xpath("app/requests-for-export/requests-for-export[1]/steps/step[1]/script") }
        it { should have_xpath("app/requests-for-export/requests-for-export[1]/steps/step[1]/runtime-phase/name").with_text(@runtime_phase.name) }
        it { should have_xpath("app/requests-for-export/requests-for-export[1]/steps/step[1]/runtime-phase/position").with_text(@runtime_phase.position) }
      end
    end
  end

  describe 'export /v1/apps/[id] with requests/releases' do
    before(:each) do
      @release = create(:release)
      @request_template = create(:request_template, name: "RecurringRequest", request: create(:request_with_app,:release => @release))
      @app = @request_template.apps.first
    end

    let (:url) { app_export_url_including(:req_templates) }

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('app/name').with_text(@app.name) }
      it { should have_xpath("app/requests-for-export/requests-for-export[1]/request-template/name").with_text(@request_template.name) }
      it { should have_xpath("app/requests-for-export/requests-for-export[1]/name").with_text(@request_template.request.name) }
      it { should have_xpath("app/requests-for-export/requests-for-export[1]/release/name").with_text(@release.name) }
    end
  end

  describe 'export /v1/apps/[id] with requests/business process' do
    before(:each) do
      @business_process = create(:business_process)
      @request_template = create(:request_template, name: "RecurringRequest", request: create(:request_with_app,:business_process => @business_process))
      @app = @request_template.apps.first
    end

    let (:url) { app_export_url_including(:req_templates) }
    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('app/name').with_text(@app.name) }
      it { should have_xpath("app/requests-for-export/requests-for-export[1]/request-template/name").with_text(@request_template.name) }
      it { should have_xpath("app/requests-for-export/requests-for-export[1]/name").with_text(@request_template.request.name) }
      it { should have_xpath("app/requests-for-export/requests-for-export[1]/business-process/name").with_text(@business_process.name) }
    end
  end

  describe 'export /v1/apps/[id] with optional deployment windows' do
    before(:each) do
      @env = create(:environment, :closed)
      @app = create(:app)
      @app.environments << @env
      @dws_regular = create(:deployment_window_series, :with_occurrences, environment_ids: [@env.id], environment_names: @env.name)
      @dws_draft = create(:deployment_window_series, aasm_state: "draft", environment_ids: [@env.id], environment_names: @env.name)
    end
    let (:url) { app_export_url_including(:deployment_windows) }

    it_behaves_like "successful request", type: :xml do
      env_path = 'app/environments/environment[1]'
      subject { response.body }
      it { should have_xpath('app/name').with_text(@app.name) }
      it { should have_xpath("#{env_path}/name").with_text(@env.name) }
      it { should have_xpath("#{env_path}/active-deployment-window-series/active-deployment-window-series[1]/name").with_text(@dws_regular.name) }
      it { should have_xpath("#{env_path}/active-deployment-window-series/active-deployment-window-series[1]/aasm-state").with_text(@dws_regular.aasm_state) }
      it { should_not have_xpath("#{env_path}/active-deployment-window-series/active-deployment-window-series[2]") }
    end
  end

  describe 'export /v1/apps/[id] with package' do
    before(:each) do
      @package = create(:package)
      @reference = create(:reference, package: @package)
      @app = create(:app)
      @app.packages << @package
    end

    let (:url) { "#{base_url}/#{@app.id}?token=#{@user.api_key}&export_xml=true" }

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('app/name').with_text(@app.name) }
      it { should have_xpath("app/active-packages/active-package[1]/name").with_text(@package.name) }
      it { should have_xpath("app/active-packages/active-package[1]/instance-name-format").with_text(@package.instance_name_format) }
      it { should have_xpath("app/active-packages/active-package[1]/references/reference[1]/uri").with_text(@reference.uri) }
    end
  end

  def have_automation_script(xpath="")
    if xpath.present?
      xpath = "/#{xpath}"
    end
    have_xpath("app/requests-for-export-with-automations/requests-for-export-with-automation[1]/request-template/automation-scripts-for-export/automation-scripts-for-export[1]#{xpath}")
  end

  def have_request(xpath="")
    if xpath.present?
      xpath = "/#{xpath}"
    end
    have_xpath("app/requests-for-export/requests-for-export[1]#{xpath}")
  end

  def have_request_template(xpath="")
    if xpath.present?
      xpath = "/#{xpath}"
    end
    have_xpath("app/requests-for-export/requests-for-export[1]/request-template#{xpath}")
  end

  def app_export_url_including(*optional_components)
    optional_components = optional_components.join(',')
    "#{base_url}/#{@app.id}?token=#{@user.api_key}&export_xml=true&optional_components=[#{optional_components}]"
  end

  def create_app_with_automation_script
    step_with_script = create(:step_with_script)
    @script = step_with_script.script
    request_with_automated_steps = create(:request)
    create(:request_template, request: request_with_automated_steps)
    @app = create(:app)
    @app.requests << request_with_automated_steps
    @app.requests.first.request_template.request.steps << step_with_script
  end
end
