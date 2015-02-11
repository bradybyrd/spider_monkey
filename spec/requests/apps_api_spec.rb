require 'spec_helper'

describe '/v1/apps' do
  before :all do
    @user = create(:user)
    @token = @user.api_key
  end

  let(:base_url) { '/v1/apps' }
  let(:json_root) { :app }
  let(:xml_root) { 'app' }
  let(:params) { {token: @user.api_key} }
  subject { response }

  describe 'get /v1/apps/[id]' do
    before(:each) do
      @app =  create(:app)

      @environment_1 = create(:environment)
      @environment_2 = create(:environment)

      @route_1 = create(:route, app: @app)
      @route_2 = create(:route, app: @app, route_type: 'mixed')

      @expected_routes = [@route_1, @route_2, @app.default_route]

      @rg_11 = create(:route_gate, route: @route_1, description: 'RouteGate #1')
      @rg_12 = create(:route_gate, route: @route_1, description: 'RouteGate #2')
      @rg_2 = create(:route_gate, route: @route_2, description: 'RouteGate #3')

      @expected_route_gates = [@rg_11, @rg_12, @rg_2]
    end
    let(:url) { "#{base_url}/#{@app.id}?token=#{@token}" }

    it_behaves_like 'successful request', type: :json do
      subject { response.body }
      it { should have_json('number.id').with_value(@app.id) }
      it { should have_json('string.name').with_value(@app.name) }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }

      it { should have_json('array.routes > object > number.id').with_values(@expected_routes.map(&:id)) }
      it { should have_json('array.routes > object > string.name').with_values(@expected_routes.map(&:name)) }
      it { should have_json('array.routes > object > string.route_type').with_values(@expected_routes.map(&:route_type)) }
      it { should have_json('array.routes > object > array.route_gates > object > number.id').with_values(@expected_route_gates.map(&:id)) }
      it { should have_json('array.routes > object > array.route_gates > object > string.description').with_values(@expected_route_gates.map(&:description)) }
    end

    it_behaves_like 'successful request', type: :xml do
      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(@app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(@app.name) }
      it { should have_xpath("#{xml_root}/created-at") }
      it { should have_xpath("#{xml_root}/updated-at") }

      it { should have_xpath("#{xml_root}/routes/route/id").with_texts(@expected_routes.map(&:id)) }
      it { should have_xpath("#{xml_root}/routes/route/name").with_texts(@expected_routes.map(&:name)) }
      it { should have_xpath("#{xml_root}/routes/route/route-type").with_texts(@expected_routes.map(&:route_type)) }
      it { should have_xpath("#{xml_root}/routes/route/route-gates/route-gate/id").with_texts(@expected_route_gates.map(&:id)) }
      it { should have_xpath("#{xml_root}/routes/route/route-gates/route-gate/description").with_texts(@expected_route_gates.map(&:description)) }
      it { should_not have_xpath('app/brpm_version') }
    end

    it_behaves_like 'entity with include_exclude support' do
      let(:excludes) { %w(requests steps) }
    end
  end

  describe 'get /v1/apps' do
    before(:each) { @app = create(:app) }
    let(:url) { "#{base_url}?token=#{@token}" }
    let(:xml_root) { 'apps/app' }

    it_behaves_like 'successful request', type: :json do
      subject { response.body }
      it { should have_json('number.id').with_value(@app.id) }
    end

    it_behaves_like 'successful request', type: :xml do
      subject { response.body }
      it { should have_xpath("#{xml_root}[1]/id").with_text(@app.id) }
    end

    it_behaves_like 'entity with include_exclude support' do
      let(:excludes) { %w(requests steps) }
    end
  end

  describe 'post /v1/apps' do
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :json, method: :post, status: 201 do
      let(:app_name)    { "JSON App #{Time.now.to_i}" }
      let(:app_version) { "#{Time.now.to_i}" }
      let(:new_team)    { create(:team) }
      let(:app_params)  { { name: app_name, app_version: app_version, team_ids: [new_team.id] } }
      let(:params)      { { json_root => app_params }.to_json }
      let(:added_app)   { App.where(name: app_name).first }

      subject { response.body }
      it { should have_json('number.id').with_value(added_app.id) }
      it { should have_json('string.name').with_value(added_app.name) }
      it { should have_json('string.app_version').with_value(added_app.app_version) }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }
      it { should have_json('boolean.active').with_value(true) }
      it { should have_json('array.teams string.name').with_value(new_team.name) }
    end

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      let(:app_name)    { "XML App #{Time.now.to_i}" }
      let(:app_version) { "#{Time.now.to_i}" }
      let(:new_team)    { create(:team) }
      let(:app_params)  { { name: app_name, app_version: app_version, team_ids: [new_team.id] } }
      let(:params)      { app_params.to_xml(root: xml_root )}
      let(:added_app)   { App.where(name: app_name).first }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_app.name) }
      it { should have_xpath("#{xml_root}/app-version").with_text(added_app.app_version) }
      it { should have_xpath("#{xml_root}/created-at") }
      it { should have_xpath("#{xml_root}/updated-at") }
      it { should have_xpath("#{xml_root}/active").with_text('true') }
      it { should have_xpath("#{xml_root}/teams/team/name").with_text(new_team.name) }
    end

    it_behaves_like 'creating request with params that fails validation' do
      let(:param) { { name: nil } }
    end

    it_behaves_like 'creating request with invalid params'
  end

  describe 'put /v1/apps/[id]' do
    before(:each) { @app = create(:app) }
    let (:url) { "#{base_url}/#{@app.id}?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :json, method: :put, status: 202 do
      let(:new_name)    { "NEW JSON App #{Time.now.to_i}" }
      let(:new_version) { "#{Time.now.to_i}" }
      let(:new_team)    { create(:team) }
      let(:app_params)  { { name: new_name, app_version: new_version, team_ids: [new_team.id] } }
      let(:params)      { { json_root => app_params }.to_json }
      let(:updated_app) { App.where(name: new_name).first }

      subject { response.body }
      it { should have_json('string.name').with_value(updated_app.name) }
      it { should have_json('string.app_version').with_value(updated_app.app_version) }
      it { should have_json('array.teams string.name').with_value(new_team.name) }
    end

    it_behaves_like 'successful request', type: :xml, method: :put, status: 202 do
      let(:new_name)    { "NEW XML App #{Time.now.to_i}" }
      let(:new_version) { "#{Time.now.to_i}" }
      let(:new_team)    { create(:team) }
      let(:app_params)  { { name: new_name, app_version: new_version, team_ids: [new_team.id] } }
      let(:params)      { app_params.to_xml(root: xml_root) }
      let(:updated_app) { App.where(name: new_name).first }

      subject { response.body }
      it { should have_xpath("#{xml_root}/name").with_text(updated_app.name) }
      it { should have_xpath("#{xml_root}/app-version").with_text(updated_app.app_version) }
      it { should have_xpath("#{xml_root}/teams/team/name").with_text(new_team.name) }
    end

    it_behaves_like 'change `active` param'

    it_behaves_like 'editing request with params that fails validation' do
      let(:param) { {name: nil} }
    end

    it_behaves_like 'editing request with invalid params'
  end

  describe 'delete /v1/apps/[id]' do

    tested_formats.each do |format|
      context 'delete apps' do
        before(:each) { @app = create(:app) }
        let(:url) { "#{base_url}/#{@app.id}/?token=#{@user.api_key}" }
        it_behaves_like 'successful request', type: format, method: :delete, status: 202 do
          let(:params) { { } }
        end
      end
    end
  end
end
