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

  describe 'export app json with no optional objects' do
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
    let (:url) { "#{base_url}/#{@app.id}?token=#{@user.api_key}&export_app=true" }

    it_behaves_like "successful request", type: :json do
      subject { response.body }

      it { is_expected.to have_json(':root > object > string.name').with_value(@app.name) }
      it { is_expected.to have_json(':root > object > string.brpm_version').with_value(ApplicationController.helpers.get_version_from_file) }
      it { is_expected.to_not have_request_templates_with_automations }
      it { is_expected.to_not have_servers }
      it { is_expected.to_not have_deployment_windows }

    end
  end

  describe 'export app json with all optional objects' do
    before(:each) do
      @app = create(:app,:with_installed_component)
      @business_process = create(:business_process, apps: [@app])
      @server = create(:server)
      @app.environments.each do |env|
        env.server_ids = [@server.id]
        env.save
      end
      @env = @app.environments.first
      @dws_regular = create(:deployment_window_series, :with_occurrences, environment_ids: [@env.id], environment_names: @env.name)
      @route = create(:route, app: @app)
      @route_gate = create(:route_gate, route: @route)
      @route_archived = create(:route, app: @app)
      @route_archived.toggle_archive
    end
    let (:url) { app_export_url_including(:req_templates, :automations, :servers, :deployment_windows) }

    it_behaves_like "successful request", type: :json do
      subject { response.body }

      it { is_expected.to have_json(':root > object > string.name').with_value(@app.name) }
      it { is_expected.to have_json(':root > object > string.brpm_version').with_value(ApplicationController.helpers.get_version_from_file) }
      it { is_expected.to have_request_templates_with_automations }
      it { is_expected.to have_servers }
      it { is_expected.to have_deployment_windows }

    end
  end

  def app_export_url_including(*optional_components)
    optional_components = optional_components.join(',')
    "#{base_url}/#{@app.id}?token=#{@user.api_key}&export_app=true&optional_components=[#{optional_components}]"
  end

  def have_request_templates_with_automations
    have_json(':root > object > array.requests_for_export_with_automations')
  end

  def have_servers
    have_json('.environments .active_environment_servers')
  end

  def have_deployment_windows
    have_json('.environments .active_deployment_window_series')
  end
end
