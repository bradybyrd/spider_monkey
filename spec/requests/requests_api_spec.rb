require 'spec_helper'

describe 'v1/requests' do

  before(:each) do
    @user = create(:old_user)
    User.current_user = @user
  end

  let(:base_url) { 'v1/requests' }
  let(:params) { {token: @user.api_key} }
  let(:json_root) { :request }
  let(:xml_root) { 'request' }

  describe 'get v1/requests' do

    let(:url) { "#{base_url}?token=#{@user.api_key}" }

    describe "without filters" do

      before(:each) do
        @req1 = create(:request)
        @req2 = create(:request)
      end
      let(:arr_id) { [@req1.id, @req2.id] }
      let(:arr_name) { [@req1.name, @req2.name] }
      let(:arr_deployment_coordinator_id) { [@req1.deployment_coordinator_id, @req2.deployment_coordinator_id] }
      let(:arr_requestor_id) { [@req1.requestor_id, @req2.requestor_id] }

      it_behaves_like "successful request", type: :json do
        subject { response.body }

        it { should have_json(':root > object > number.id').with_values(arr_id) }
        it { should have_json(':root > object > string.name').with_values(arr_name) }
        it { should have_json('.deployment_coordinator .id').with_values(arr_deployment_coordinator_id) }
        it { should have_json('.requestor .id').with_values(arr_requestor_id) }
        it { should have_json('string.created_at') }
        it { should have_json('string.updated_at') }
      end

      it_behaves_like "successful request", type: :xml do
        subject { response.body }
        it { should have_xpath('/requests/request/id').with_texts(arr_id) }
        it { should have_xpath('/requests/request/name').with_texts(arr_name) }
        it { should have_xpath('/requests/request/deployment-coordinator/id').with_texts(arr_deployment_coordinator_id) }
        it { should have_xpath('/requests/request/requestor/id').with_texts(arr_requestor_id) }
        it { should have_xpath('/requests/request/created-at') }
        it { should have_xpath('/requests/request/updated-at') }
      end
    end

    describe "with filters" do

      before(:each) do
        @main_request = create(:request)
      end

      subject { response.body }

      describe "filtered by aasm_state" do

        let(:params) { {filters: {aasm_state: [@main_request.aasm_state]}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_request.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/id').with_text(@main_request.id) }
        end
      end

      describe "filtered by activity_id" do
        let(:params) { {filters: {activity_id: @main_request.activity_id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_request.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/id').with_text(@main_request.id) }
        end
      end

      describe "filtered by app_id" do

        before(:each) do
          @app = create(:app)
          @env = create(:environment)
          @app.environments << @env
          AssignedEnvironment.create!(:environment_id => @env.id, :assigned_app_id => @app.assigned_apps.first.id, :role => @user.roles.first)
          @req_7 = create(:request, :apps => [@app], :environment_id => @env.id)
        end

        let(:params) { {filters: {app_id: @app.id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('.apps .id').with_values(@req_7.apps.map(&:id)) }
          it { response.body.should have_json('.id').with_value(@req_7.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/apps/app/id').with_texts(@req_7.apps.map(&:id)) }
          it { response.body.should have_xpath('/requests/request/id').with_text(@req_7.id) }
        end
      end

      describe "filtered by assignee_id" do

        before(:each) do
          @step = create(:step, :request => @main_request)
        end
        let(:params) { {filters: {assignee_id: [@step.owner_id]}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_request.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/id').with_text(@main_request.id) }
        end
      end

      describe "filtered by business_process_id" do

        before(:each) do
          @business_process = create(:business_process)
          @req_5 = create(:request, :business_process => @business_process)
        end

        let(:params) { {filters: {business_process_id: @business_process.id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('.business_process .id').with_value(@req_5.business_process_id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/business-process/id').with_text(@req_5.business_process_id) }
        end
      end

      describe "filtered by group_id" do
        before(:each) do
          @step = create(:step, :procedure => true, :request => @main_request, :owner_type => 'Group')
        end

        let(:params) { {filters: {group_id: @step.owner_id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_request.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/id').with_text(@main_request.id) }
        end
      end

      describe "filtered by in_progress" do

        before(:each) do
          @req_3 = create(:request, :aasm_event => "plan_it")
        end

        let(:params) { {filters: {in_progress: true}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@req_3.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/id').with_text(@req_3.id) }
        end
      end

      describe "filtered by name" do
        let(:params) { {filters: {name: @main_request.name}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('string.name').with_value(@main_request.name) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/name').with_text(@main_request.name) }
        end
      end

      describe "filtered by number" do
        let(:request_number) { @main_request.id + GlobalSettings.new.base_request_number }
        let(:params) { {filters: {number: request_number}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_request.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/id').with_text(@main_request.id) }
        end
      end

      describe "filtered by owner_id" do
        before(:each) do
          @owner = create(:user)
          @req_4 = create(:request, :owner => @owner)
        end

        let(:params) { {filters: {owner_id: @req_4.owner_id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('.owner .id').with_value(@req_4.owner_id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/owner/id').with_text(@req_4.owner_id) }
        end
      end

      describe "filtered by package_content_id" do

        before(:each) do
          @package_content = create(:package_content)
          @req_6 = create(:request)
          @req_6.package_contents << @package_content
          @req_6.reload
        end

        let(:params) { {filters: {package_content_id: [@package_content.id]}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@req_6.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/id').with_text(@req_6.id) }
        end
      end

      describe "filtered by participated_in_by" do
        let(:params) { {filters: {participated_in_by: @main_request.deployment_coordinator_id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('.deployment_coordinator .id').with_value(@main_request.deployment_coordinator_id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/deployment-coordinator/id').with_text(@main_request.deployment_coordinator_id) }
        end
      end

      describe "filtered by plan_member_id" do
        let(:params) { {filters: {plan_member_id: @main_request.plan_member_id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('.plan_member .id').with_value(@main_request.plan_member_id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/plan-member/id').with_text(@main_request.plan_member_id) }
        end
      end

      describe "filtered by release_id" do
        let(:params) { {filters: {release_id: @main_request.release_id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_request.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/id').with_text(@main_request.id) }
        end
      end

      describe "filtered by environment_id" do
        let(:params) { {filters: {environment_id: @main_request.environment_id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('.environment .id').with_value(@main_request.environment_id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/environment/id').with_text(@main_request.environment_id) }
        end
      end

      describe "filtered by requestor_id" do
        let(:params) { {filters: {requestor_id: @main_request.requestor_id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('.requestor .id').with_value(@main_request.requestor_id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/requestor/id').with_text(@main_request.requestor_id) }
        end
      end

      describe "filtered by request_template_id" do
        before(:each) do
         @request_template = create(:request_template)
        end

        let(:params) { {filters: {request_template_id: @request_template.id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@request_template.request.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/id').with_text(@request_template.request.id) }
        end
      end

      #describe "filtered by server_association_id" do
      #  before(:each) do
      #    @server = create(:user)
      #    req_5 = create(:request, :server => @server)
      #  end
      #
      #  let(:params) { { filters: { server_association_id: req_5.server_association_id } } }
      #
      #  it_behaves_like "successful request", type: :json do
      #    it { response.body.should have_json('number .server_association_id').with_value(@req_5.server_association_id) }
      #  end
      #
      #  it_behaves_like "successful request", type: :xml do
      #    it { response.body.should have_xpath('/requests/request/server-association-id').with_text(@req_5.server_association_id) }
      #  end
      #end

      describe "filtered by team_id" do

        before(:each) do
          @team = create(:team)
          @app = create(:app, :requests => [@main_request])
          @development_team = create(:development_team, :app_id => @app.id, :team_id => @team.id)
        end

        let(:params) { {filters: {team_id: @team.id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('.requestor .id').with_value(@main_request.requestor_id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/requests/request/requestor/id').with_text(@main_request.requestor_id) }
        end
      end

      describe 'filter by deployment window event id' do
        let(:deployment_window_event) { create :deployment_window_event, :with_allow_series }
        let(:req_with_dw)             { create :request, deployment_window_event: deployment_window_event}

        let(:params) { { filters: { deployment_window_event_id: deployment_window_event.id } } }
        before { req_with_dw } # touch variable so it's created in time
        it_behaves_like 'successful request', type: :json do
          it { should have_json('object.deployment_window_event number.id').with_value(deployment_window_event.id) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { should have_xpath('/requests/request/deployment-window-event/id').with_text(deployment_window_event.id) }
        end
      end
    end
  end

  describe 'get v1/requests/[id]' do

    before(:each) do
      @req = create(:request)
    end

    let(:url) { "#{base_url}/#{@req.id}" }

    it_behaves_like "successful request", type: :json do
      subject { response.body }
      it { should have_json('number.id').with_value(@req.id) }
      it { should have_json('string.name').with_value(@req.name) }
      it { should have_json('.deployment_coordinator .id').with_value(@req.deployment_coordinator_id) }
      it { should have_json('.requestor .id').with_value(@req.requestor_id) }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }
    end

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('/request/id').with_text(@req.id) }
      it { should have_xpath('/request/name').with_text(@req.name) }
      it { should have_xpath('/request/deployment-coordinator/id').with_text(@req.deployment_coordinator_id) }
      it { should have_xpath('/request/requestor/id').with_text(@req.requestor_id) }
      it { should have_xpath('/request/created-at') }
      it { should have_xpath('/request/updated-at') }
    end

    describe 'checks steps data' do
      let(:resource_attributes) {
                                  [:id, :name, :component_version, :aasm_state,
                                   :work_started_at, :work_finished_at, :manual,
                                   :position, :component_id, :installed_component_id,
                                   :number, :component_name]
                                }

      let(:real_resource) { create(:step, component: create(:component), installed_component_id: create(:installed_component).id) }
      before { @req.steps << real_resource }

      it_behaves_like 'successful request', type: :json do
        it_behaves_like 'has valid resource data', type: :json, resource: :steps
      end

      it_behaves_like 'successful request', type: :xml do
        it_behaves_like 'has valid resource data', type: :xml, resource: :steps
      end
    end
  end

  describe 'post v1/requests' do
    let(:url) { "#{base_url}?token=#{@user.api_key}" }

    let(:environment) { create(:environment) }

    it_behaves_like 'successful request', type: :json, method: :post, status: 201 do
      let(:request_name) { "JSON Request #{Time.now.to_i}" }
      let(:requestor_id) { @user.id }
      let(:deployment_coordinator_id) { @user.id }
      let(:params) { {json_root => {name: request_name,
                                    requestor_id: requestor_id,
                                    deployment_coordinator_id: deployment_coordinator_id,
                                    environment_id: environment.id}}.to_json }
      let(:added_request) { Request.where(name: request_name).first }

      subject { response.body }
      it { should have_json('number.id').with_value(added_request.id) }
      it { should have_json('string.name').with_value(added_request.name) }
      it { should have_json('.deployment_coordinator .id').with_value(added_request.deployment_coordinator_id) }
      it { should have_json('.requestor .id').with_value(added_request.requestor_id) }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }
    end

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      let(:request_name) { "XML Request #{Time.now.to_i}" }
      let(:requestor_id) { @user.id }
      let(:deployment_coordinator_id) { @user.id }
      let(:params) { {name: request_name,
                      requestor_id: requestor_id,
                      deployment_coordinator_id: deployment_coordinator_id,
                      environment_id: environment.id}.to_xml(root: xml_root) }
      let(:added_request) { Request.where(name: request_name).first }

      subject { response.body }
      it { should have_xpath('/request/id').with_text(added_request.id) }
      it { should have_xpath('/request/name').with_text(added_request.name) }
      it { should have_xpath('/request/deployment-coordinator/id').with_text(added_request.deployment_coordinator_id) }
      it { should have_xpath('/request/requestor/id').with_text(added_request.requestor_id) }
      it { should have_xpath('/request/created-at') }
      it { should have_xpath('/request/updated-at') }
    end

    it_behaves_like 'creating request with params that fails validation' do
      let(:param) { { :requestor_id => nil, :deployment_coordinator_id => nil, :environment_id => environment.id } }
    end

    it_behaves_like 'creating request with invalid params'
  end

  describe 'post v1/requests using multi environments' do
    let(:url) { "#{base_url}?token=#{@user.api_key}" }
    let(:test_app) { create(:app) }
    let(:env1) { create(:environment) }
    let(:env2) { create(:environment) }
    let!(:app_envs) { test_app.environment_ids = [env1.id, env2.id] }
    let!(:assigned_envs) {
      AssignedEnvironment.create!(environment_id: env1.id, assigned_app_id: test_app.assigned_apps.first.id, role: @user.roles.first)
      AssignedEnvironment.create!(environment_id: env2.id, assigned_app_id: test_app.assigned_apps.first.id, role: @user.roles.first)
    }
    let(:request_params) { { name: 'Request_001', environment_ids: "#{env1.id},#{env2.id}",
                             requestor_id: @user.id, deployment_coordinator_id: @user.id } }

    describe 'creates requests for each environment' do
      it 'using mimetype JSON' do
        params = { json_root => request_params }.to_json

        jpost params
        expect(Request.count).to eq 2
      end

      it 'using mimetype XML' do
        params = request_params.to_xml(root: xml_root)

        xpost params
        expect(Request.count).to eq 2
      end
    end

    describe 'creates requests for each environment from template' do
      let(:request_template) { create(:request_template) }

      it 'using mimetype JSON' do
        request_params.merge!({request_template_id: request_template.id})
        params = { json_root => request_params }.to_json

        jpost params
        expect(Request.count).to eq 3
      end

      it 'using mimetype XML' do
        request_params.merge!({request_template_id: request_template.id})
        params = request_params.to_xml(root: xml_root)

        xpost params
        expect(Request.count).to eq 3
      end
    end

    it_behaves_like 'creating request with params that fails validation' do
      let(:param) { {:name => 'Request_001', :app_ids => test_app.id, :environment_ids => '',
                     :requestor_id => @user.id, :deployment_coordinator_id => @user.id} }
    end
  end

  describe 'put /v1/requests/[id]' do
    before(:each) do
      @new_user = create(:user)
      @req = create(:request)
    end

    let(:url) { "#{base_url}/#{@req.id}?token=#{@user.api_key}" }

    it_behaves_like 'editing request with params that fails validation' do
      let(:param) { {:requestor_id => @new_user.id, :deployment_coordinator_id => nil } }
    end

    it_behaves_like 'editing request with invalid params'

    context 'json' do
      it_behaves_like 'successful request', type: :json, method: :put, status: 202 do
        let(:new_request_name) { "NEW JSON Request #{Time.now.to_i}" }
        let(:new_requestor_id) { @new_user.id }
        let(:new_deployment_coordinator_id) { @new_user.id }
        let(:params) { {json_root => {name: new_request_name,
                                      requestor_id: new_requestor_id,
                                      deployment_coordinator_id: new_deployment_coordinator_id}}.to_json }
        let(:updated_request) { Request.where(name: new_request_name).first }

        subject { response.body }
        it { should have_json('number.id').with_value(updated_request.id) }
        it { should have_json('string.name').with_value(updated_request.name) }
        it { should have_json('.deployment_coordinator .id').with_value(updated_request.deployment_coordinator_id) }
        it { should have_json('.requestor .id').with_value(updated_request.requestor_id) }
        it { should have_json('string.created_at') }
        it { should have_json('string.updated_at') }
      end

      it 'should be able to assign deployment window to request' do
        dwe     = create :deployment_window_event, :with_allow_series
        params  = {json_root => {deployment_window_event_id: dwe.id}}.to_json

        jput params

        response.body.should have_json('object.deployment_window_event > number.id').with_value(dwe.id)
        @req.reload.deployment_window_event.should eq dwe
      end
    end

    context 'xml' do
      it_behaves_like 'successful request', type: :xml, method: :put, status: 202 do
        let(:new_request_name) { "NEW XML Request #{Time.now.to_i}" }
        let(:new_requestor_id) { @new_user.id }
        let(:new_deployment_coordinator_id) { @new_user.id }
        let(:params) { {name: new_request_name,
                        requestor_id: new_requestor_id,
                        deployment_coordinator_id: new_deployment_coordinator_id}.to_xml(root: xml_root) }
        let(:updated_request) { Request.where(name: new_request_name).first }

        subject { response.body }
        it { should have_xpath('/request/id').with_text(updated_request.id) }
        it { should have_xpath('/request/name').with_text(updated_request.name) }
        it { should have_xpath('/request/deployment-coordinator/id').with_text(updated_request.deployment_coordinator_id) }
        it { should have_xpath('/request/requestor/id').with_text(updated_request.requestor_id) }
        it { should have_xpath('/request/created-at') }
        it { should have_xpath('/request/updated-at') }
      end

      it 'should be able to assign deployment window to request' do

      end

      it_behaves_like 'editing request with params that fails validation' do
        let(:param) { {:requestor_id => @new_user.id, :deployment_coordinator_id => nil } }
      end

      it_behaves_like 'editing request with invalid params'
      end
  end

  describe 'delete /v1/requests/[id]' do
    tested_formats.each do |format|
      context 'delete requests' do

        before(:each) do
          @req = create(:request)
        end

        let(:url) { "#{base_url}/#{@req.id}/?token=#{@user.api_key}" }

        it_behaves_like "successful request", type: format, method: :delete, status: 202 do
          let(:params) { {} }
          it { Request.exists?(@req.id).should be_falsey }
        end
      end
    end
  end
end
