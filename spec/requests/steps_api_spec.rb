require 'spec_helper'

shared_examples 'state filter' do |state|
  before(:each) do
    Step.destroy_all
    @step_with_state = create(:step, :aasm_state => state)
  end

  let(:params) { { filters: { aasm_state: state } } }
  it_behaves_like "successful request", type: :json do
    it { response.body.should have_json('number.id').with_value(@step_with_state.id) }
  end

  it_behaves_like "successful request", type: :xml do
    it { response.body.should have_xpath('/steps/step/id').with_text(@step_with_state.id) }
  end
  after { Step.destroy_all}
end

describe 'v1/steps' do
  before :all do
    @user = create(:user)
    User.current_user = @user
  end

  let(:base_url) { '/v1/steps' }
  let(:json_root) { :step }
  let(:xml_root) { 'step' }
  let(:params) { {token: @user.api_key} }

  describe 'GET /v1/steps' do

    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    describe "without filters" do
      before :each do
        @request_ = create(:request)
        @owner = create(:user)
        @step_1 = create(:step, :request => @request_, :owner => @owner)
        @step_2 = create(:step, :request => @request_, :owner => @owner)
      end

      let(:arr_ids) { [@step_1.id, @step_2.id] }
      let(:arr_names) { [@step_1.name, @step_2.name] }
      let(:request_names) { [@request_.name, @request_.name] }
      let(:request_numbers) { [@request_.number, @request_.number] }
      let(:request_states) { [@request_.aasm_state, @request_.aasm_state] }
      let(:owner_ids) { [@owner.id, @owner.id] }
      let(:owner_logins) { [@owner.login, @owner.login] }

      it_behaves_like "successful request", type: :json do
        subject { response.body }
        it { should have_json(':root > object > number.id').with_values(arr_ids) }
        it { should have_json(':root > object > string.name').with_values(arr_names) }
        it { should have_json('.request .number').with_values(request_numbers) }
        it { should have_json('.request .name').with_values(request_names) }
        it { should have_json('.request .aasm_state').with_values(request_states) }
        it { should have_json('.owner .id').with_values(owner_ids) }
        it { should have_json('.owner .login').with_values(owner_logins) }
      end

      it_behaves_like "successful request", type: :xml do
        subject { response.body }
        it { should have_xpath('/steps/step/id').with_texts(arr_ids) }
        it { should have_xpath('/steps/step/name').with_texts(arr_names) }
        it { should have_xpath('/steps/step/request/number').with_texts(request_numbers) }
        it { should have_xpath('/steps/step/request/name').with_texts(request_names) }
        it { should have_xpath('/steps/step/request/aasm-state').with_texts(request_states) }
        it { should have_xpath('/steps/step/owner/id').with_texts(owner_ids) }
        it { should have_xpath('/steps/step/owner/login').with_texts(owner_logins) }
      end
    end

    describe "with filters" do
      describe "filtered by aasm_state" do
        [:locked,:ready,:in_process,:blocked,:problem,:being_resolved,:complete].each do |state|
          it_behaves_like 'state filter', state
        end
      end

      before :each do
        @main_step = create(:step)
      end

      describe "filtered by name" do
        let(:params) { { filters: { name: @main_step.name } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_step.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@main_step.id) }
        end
      end

      describe "filtered by request_id" do
        let(:params) { { filters: { request_id: @main_step.request_id } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_step.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@main_step.id) }
        end
      end

      describe "filtered by running" do
        let(:params) { { filters: { running: true } } }

        ["in_process", "ready", "problem"].each do |state|
          context 'by running' do
            before(:each) { @_step = create(:step, :aasm_state => state) }

            it_behaves_like "successful request", type: :json do
              it { response.body.should have_json('number.id').with_value(@_step.id) }
            end

            it_behaves_like "successful request", type: :xml do
              it { response.body.should have_xpath('/steps/step/id').with_text(@_step.id) }
            end
          end
        end
      end

      describe "filtered user_id" do
        let(:params) { { filters: { user_id: @main_step.owner_id } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_step.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@main_step.id) }
        end
      end

      describe "filtered group_id" do
        before :each do
          @group = create(:group)
          @step_3 = create(:step ,:owner => @group)
        end

        let(:params) { { filters: { group_id: @group.id } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@step_3.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@step_3.id) }
        end
      end

      describe "filtered installed_component_id" do
        before :each do
          Step.delete_all
          @installed_component = create(:installed_component)
          @step_1 = create(:step ,:installed_component_id => @installed_component.id)
        end

        let(:params) { { filters: { installed_component_id: @step_1.installed_component_id } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@step_1.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@step_1.id) }
        end
      end

      describe "filtered component_version" do

        before(:each) { @main_step.update_attributes(:component_version => "1.0") }

        let(:params) { { filters: { component_version: @main_step.component_version } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_step.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@main_step.id) }
        end
      end

      describe "filtered version_tag_id" do
        before(:each) { @main_step.update_attributes(:version_tag_id => 33) }

        let(:params) { { filters: { version_tag_id: @main_step.version_tag_id } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_step.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@main_step.id) }
        end
      end

      describe "filtered custom_ticket_id" do
        before(:each) { @main_step.update_attributes(:custom_ticket_id => 32) }

        let(:params) { { filters: { custom_ticket_id: @main_step.custom_ticket_id } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_step.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@main_step.id) }
        end
      end

      describe "filtered package_template_id" do
        before :each do
          @app = create(:app)
          @package_template = create(:package_template, :app => @app, :name => "NameOfPackageTemplate", :version => "1.0" )
          @step_2 = create(:step ,:package_template => @package_template)
        end

        let(:params) { { filters: { package_template_id: @step_2.package_template_id } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@step_2.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@step_2.id) }
        end
      end

      describe "filtered script_id" do
        before(:each) { @main_step.update_attributes(:script_id => 31) }
        let(:params) { { filters: { script_id: @main_step.script_id } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_step.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@main_step.id) }
        end
      end

      describe "filtered runtime_phase_id" do
        before(:each) { @main_step.update_attributes(:runtime_phase_id => 30) }

        let(:params) { { filters: { runtime_phase_id: @main_step.runtime_phase_id } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_step.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@main_step.id) }
        end
      end

      describe "filtered phase_id" do
        before(:each) { @main_step.update_attributes(:phase_id => 29) }

        let(:params) { { filters: { phase_id: @main_step.phase_id } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_step.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@main_step.id) }
        end
      end

      describe "filtered procedure_id" do
        before(:each) { @main_step.update_attributes(:procedure_id => 28) }

        let(:params) { { filters: { procedure_id: @main_step.procedure_id} } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_step.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@main_step.id) }
        end
      end

      describe "filtered parent_id" do
        before(:each) { @main_step.update_attributes(:parent_id => 27) }

        let(:params) { { filters: { parent_id: @main_step.parent_id} } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_step.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@main_step.id) }
        end
      end

      describe "filtered category_id" do
        before(:each) { @main_step.update_attributes(:category_id => 26) }

        let(:params) { { filters: { category_id: @main_step.category_id} } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_step.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@main_step.id) }
        end
        end

      describe "filtered work_task_id" do
        before(:each) { @main_step.update_attributes(:work_task_id => 25) }

        let(:params) { { filters: { work_task_id: @main_step.work_task_id} } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@main_step.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/steps/step/id').with_text(@main_step.id) }
        end
      end
    end
  end

  describe 'GET /v1/steps/[id]' do
    before :each do
      @request_ = create(:request)
      @owner = create(:user)
      @step_1 = create(:step, :request => @request_, :owner => @owner)
    end

    let(:url) { "#{base_url}/#{@step_1.id}" }

    it_behaves_like "successful request", type: :json do
      subject { response.body }
      it { should have_json('number.id').with_value(@step_1.id) }
      it { should have_json('string.name').with_value(@step_1.name) }
      it { should have_json('.request .number').with_value(@request_.number) }
      it { should have_json('.request .name').with_value(@request_.name) }
      it { should have_json('.request .aasm_state').with_value(@request_.aasm_state) }
      it { should have_json('.owner .id').with_value(@owner.id) }
      it { should have_json('.owner .login').with_value(@owner.login) }
    end

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('/step/id').with_text(@step_1.id) }
      it { should have_xpath('/step/name').with_text(@step_1.name) }
      it { should have_xpath('/step/request/number').with_text(@request_.number) }
      it { should have_xpath('/step/request/name').with_text(@request_.name) }
      it { should have_xpath('/step/request/aasm-state').with_text(@request_.aasm_state) }
      it { should have_xpath('/step/owner/id').with_text(@owner.id) }
      it { should have_xpath('/step/owner/login').with_text(@owner.login) }
    end
  end

  describe 'POST /v1/steps' do
    before :each do
      @owner = create(:user)
      @request_ = create(:request)
    end

    let(:url) { "#{base_url}?token=#{@user.api_key}" }

    let(:owner_id) { @owner.id }
    let(:owner_type) { "User" }
    let(:request_id) { @request_.id }
    let(:description) { "description" }

    it_behaves_like 'successful request', type: :json, method: :post, status: 201 do
      let(:name) { "JSONName" }
      let(:params) { {json_root => {name: name,
                                    owner_id: owner_id,
                                    owner_type: owner_type,
                                    request_id: request_id,
                                    description: description}}.to_json }

      let(:added_step) { Step.where(name: name).first }

      subject { response.body }
      it { should have_json('number.id').with_value(added_step.id) }
      it { should have_json('string.name').with_value(added_step.name) }
      it { should have_json('string.description').with_value(added_step.description) }
      it { should have_json('.owner .id').with_value(added_step.owner_id) }
    end

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      let(:name) { "XMLName" }
      let(:params) { {name: name,
                      owner_id: owner_id,
                      owner_type: owner_type,
                      request_id: request_id,
                      description: description}.to_xml(root: xml_root) }

      let(:added_step) { Step.where(name: name).first }

      subject { response.body }
      it { should have_xpath('/step/id').with_text(added_step.id) }
      it { should have_xpath('/step/name').with_text(added_step.name) }
      it { should have_xpath('/step/description').with_text(added_step.description) }
      it { should have_xpath('/step/owner/id').with_text(added_step.owner_id) }
    end

    it_behaves_like 'creating request with params that fails validation' do
      let(:param) { {:name => 'test step', :request_id => request_id} }
    end

    it_behaves_like 'creating request with invalid params'
  end

  describe 'PUT /v1/steps/[id]' do
    before :each do
      @step_put = create(:step)
      @request_ = create(:request)
      @owner = create(:user)
    end

    let(:url) { "#{base_url}/#{@step_put.id}?token=#{@user.api_key}" }

    let(:owner_id) { @owner.id }
    let(:owner_type) { "User" }
    let(:request_id) { @request_.id }
    let(:description) { "description" }

    it_behaves_like 'successful request', type: :json, method: :put, status: 202 do
      let(:name) { "JSONPUTName" }
      let(:params) { {json_root => {name: name,
                                    owner_id: owner_id,
                                    owner_type: owner_type,
                                    description: description,
                                    request_id: request_id}}.to_json }

      let(:updated_step) { Step.where(name: name).first }

      subject { response.body }
      it { should have_json('number.id').with_value(updated_step.id) }
      it { should have_json('string.name').with_value(updated_step.name) }
      it { should have_json('string.description').with_value(updated_step.description) }
      it { should have_json('.owner .id').with_value(updated_step.owner_id) }
    end

    it_behaves_like 'successful request', type: :xml, method: :put, status: 202 do
      let(:name) { "XML_PUT_Name" }
      let(:params) { {name: name,
                      owner_id: owner_id,
                      owner_type: owner_type,
                      description: description,
                      request_id: request_id}.to_xml(root: xml_root) }

      let(:updated_step) { Step.where(name: name).first }

      subject { response.body }
      it { should have_xpath('/step/id').with_text(updated_step.id) }
      it { should have_xpath('/step/name').with_text(updated_step.name) }
      it { should have_xpath('/step/description').with_text(updated_step.description) }
      it { should have_xpath('/step/owner/id').with_text(updated_step.owner_id) }
    end

    it_behaves_like 'editing request with params that fails validation' do
      let(:param) { {:owner => nil} }
    end

    it_behaves_like 'editing request with invalid params'
  end

  describe 'DELETE /v1/steps/[id]' do
    tested_formats.each do |format|
      context 'delete steps' do
        before (:each) { @step = create(:step) }
        let(:url) { "#{base_url}/#{@step.id}/?token=#{@user.api_key}" }
        it_behaves_like "successful request", type: format, method: :delete, status: 202 do
          let(:params) { { } }
          it { Step.exists?(@step.id).should be_falsey }
        end
      end
    end
  end
end
