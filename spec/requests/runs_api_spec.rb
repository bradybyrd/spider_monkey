require 'spec_helper'

describe 'v1/runs' do
  before :all do
    @user = create(:user)
  end

  let(:base_url) { 'v1/runs' }
  let(:json_root) { :run }
  let(:xml_root) { 'run' }
  let(:params) { {token: @user.api_key} }

  describe 'GET /v1/runs' do
    before(:each) do
      @run_1 = create(:run)
      @plan_stage = create(:plan_stage)
      @run_2 = create(:run, name: "cool name", owner: @user, requestor: @user, plan_stage: @plan_stage, start_at: "2012-10-24 15:24:03 UTC", end_at: "2012-11-24 15:24:03 UTC" )
      @run_2.assign_attributes({ :aasm_state => 'planned' }, :without_protection => true)
      @run_2.save
    end

    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    describe "without filters" do
      let(:arr_ids) { [@run_1.id, @run_2.id] }
      let(:arr_name) { [@run_1.name, @run_2.name] }
      let(:arr_aasm_states) { [@run_1.aasm_state, @run_2.aasm_state] }
      let(:arr_owner_ids) { [@run_1.owner_id, @run_2.owner_id] }
      let(:arr_plan_ids) { [@run_1.plan_id, @run_2.plan_id] }
      let(:arr_requestor_ids) { [@run_1.requestor_id, @run_2.requestor_id] }

      it_behaves_like "successful request", type: :json do
        subject { response.body }
        it { should have_json(':root > object > number.id').with_values(arr_ids) }
        it { should have_json(':root > object > string.name').with_values(arr_name) }
        it { should have_json(':root > object > string.aasm_state').with_values(arr_aasm_states) }
        it { should have_json(':root > object > number.owner_id').with_values(arr_owner_ids) }
        it { should have_json(':root > object > number.plan_id').with_values(arr_plan_ids) }
        it { should have_json(':root > object > number.requestor_id').with_values(arr_requestor_ids) }
      end

      it_behaves_like "successful request", type: :xml do
        subject { response.body }
        it { should have_xpath('/runs/run/id').with_texts(arr_ids) }
        it { should have_xpath('/runs/run/name').with_texts(arr_name) }
        it { should have_xpath('/runs/run/aasm-state').with_texts(arr_aasm_states) }
        it { should have_xpath('/runs/run/owner-id').with_texts(arr_owner_ids) }
        it { should have_xpath('/runs/run/plan-id').with_texts(arr_plan_ids) }
        it { should have_xpath('/runs/run/requestor-id').with_texts(arr_requestor_ids) }
      end
    end

    describe "with filters" do
      describe "filtered by name" do
        let(:params) { { filters: { name: @run_2.name } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@run_2.id) }
          it { response.body.should have_json('string.name').with_value(@run_2.name) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/runs/run/id').with_text(@run_2.id) }
          it { response.body.should have_xpath('/runs/run/name').with_text(@run_2.name) }
        end
      end

      #describe "filtered by app_id" do
      #  let(:params) { { filters: { app_id: @run.app_id } } }
      #
      #  it_behaves_like "successful request", type: :json do
      #    it { response.body.should have_json('number.id').with_value(@run.id) }
      #  end
      #
      #  it_behaves_like "successful request", type: :xml do
      #    it { response.body.should have_xpath('/runs/run/id').with_text(@run.id) }
      #  end
      #end

      describe "filtered by aasm_state" do
        let(:params) { { filters: { aasm_state: @run_2.aasm_state } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@run_2.id) }
          it { response.body.should have_json('string.aasm_state').with_value(@run_2.aasm_state) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/runs/run/id').with_text(@run_2.id) }
          it { response.body.should have_xpath('/runs/run/aasm-state').with_text(@run_2.aasm_state) }
        end
      end

      describe "filtered by owner_id" do
        let(:params) { { filters: { owner_id: @run_2.owner_id } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@run_2.id) }
          it { response.body.should have_json('number.owner_id').with_value(@run_2.owner_id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/runs/run/id').with_text(@run_2.id) }
          it { response.body.should have_xpath('/runs/run/owner-id').with_text(@run_2.owner_id) }
        end
      end

      describe "filtered by requestor_id" do
        let(:params) { { filters: { requestor_id: @run_2.requestor_id } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@run_2.id) }
          it { response.body.should have_json('number.requestor_id').with_value(@run_2.requestor_id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/runs/run/id').with_text(@run_2.id) }
          it { response.body.should have_xpath('/runs/run/requestor-id').with_text(@run_2.requestor_id) }
        end
      end

      describe "filtered by stage_id" do
        let(:params) { { filters: { stage_id: @run_2.plan_stage_id } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@run_2.id) }
          it { response.body.should have_json('number.plan_stage_id').with_value(@run_2.plan_stage_id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/runs/run/id').with_text(@run_2.id) }
          it { response.body.should have_xpath('/runs/run/plan-stage-id').with_text(@run_2.plan_stage_id) }
        end
      end

      describe "filtered by started_at" do
        let(:params) { { filters: { start_at: @run_2.start_at } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@run_2.id) }
          it { response.body.should have_json('string.start_at') }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/runs/run/id').with_text(@run_2.id) }
          it { response.body.should have_xpath('/runs/run/start-at') }
        end
      end

      describe "filtered by end_at" do
        let(:params) { { filters: { end_at: @run_2.end_at } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@run_2.id) }
          it { response.body.should have_json('string.end_at') }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/runs/run/id').with_text(@run_2.id) }
          it { response.body.should have_xpath('/runs/run/end-at') }
        end
      end

      describe "filtered by time" do
        let(:params) { { filters: { time: @run_2.start_at } } }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@run_2.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('/runs/run/id').with_text(@run_2.id) }
        end
      end
    end
  end

  describe 'GET /v1/runs/[id]' do
    before(:each) { @run = create(:run) }

    let(:url) { "#{base_url}/#{@run.id}?token=#{@user.api_key}" }

    it_behaves_like "successful request", type: :json do
      subject { response.body }
      it { should have_json('number.id').with_value(@run.id) }
      it { should have_json('string.name').with_value(@run.name) }
      it { should have_json('string.aasm_state').with_value(@run.aasm_state) }
      it { should have_json('number.owner_id').with_value(@run.owner_id) }
      it { should have_json('number.plan_id').with_value(@run.plan_id) }
      it { should have_json('number.requestor_id').with_value(@run.requestor_id) }
    end

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('/run/id').with_text(@run.id) }
      it { should have_xpath('/run/name').with_text(@run.name) }
      it { should have_xpath('/run/aasm-state').with_text(@run.aasm_state) }
      it { should have_xpath('/run/owner-id').with_text(@run.owner_id) }
      it { should have_xpath('/run/plan-id').with_text(@run.plan_id) }
      it { should have_xpath('/run/requestor-id').with_text(@run.requestor_id) }
    end
  end

  describe 'POST /v1/runs' do
    before :each do
      @plan = create(:plan)
      @plan_stage = create(:plan_stage)
    end

    let(:owner_id) { @user.id }
    let(:plan_id) { @plan.id }
    let(:plan_stage_id) { @plan_stage.id }
    let(:requestor_id) { @user.id }

    let(:url) { "#{base_url}?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :json, method: :post, status: 201 do
      let(:name) { "json_Run" }
      let(:params) { { json_root => { name: name,
                                      owner_id: owner_id,
                                      plan_stage_id: plan_stage_id,
                                      requestor_id: requestor_id,
                                      plan_id: plan_id }  }.to_json }
      let(:added_run) { Run.where(name: name).first }

      subject { response.body }
      it { should have_json('number.id').with_value(added_run.id) }
      it { should have_json('string.name').with_value(added_run.name) }
      it { should have_json('string.aasm_state').with_value(added_run.aasm_state) }
      it { should have_json('number.owner_id').with_value(added_run.owner_id) }
      it { should have_json('number.plan_id').with_value(added_run.plan_id) }
      it { should have_json('number.requestor_id').with_value(added_run.requestor_id) }
    end

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      let(:name) { "xml_Run" }
      let(:params) { { name: name,
                       owner_id: owner_id,
                       plan_stage_id: plan_stage_id,
                       requestor_id: requestor_id,
                       plan_id: plan_id }.to_xml(root: xml_root)}
      let(:added_run) { Run.where(name: name).first }

      subject { response.body }
      it { should have_xpath('/run/id').with_text(added_run.id) }
      it { should have_xpath('/run/name').with_text(added_run.name) }
      it { should have_xpath('/run/aasm-state').with_text(added_run.aasm_state) }
      it { should have_xpath('/run/owner-id').with_text(added_run.owner_id) }
      it { should have_xpath('/run/plan-id').with_text(added_run.plan_id) }
      it { should have_xpath('/run/requestor-id').with_text(added_run.requestor_id) }
    end

    it_behaves_like 'creating request with params that fails validation' do
      let(:param) { {:name => nil, :owner_id => nil, :requestor_id => nil, :plan_id => nil } }
    end

    it_behaves_like 'creating request with invalid params'
  end

  describe 'PUT /v1/runs/[id]' do
    before :each do
      @run = create(:run)
      @plan = create(:plan)
      @plan_stage = create(:plan_stage)
    end

    let(:owner_id) { @user.id }
    let(:plan_id) { @plan.id }
    let(:plan_stage_id) { @plan_stage.id }
    let(:requestor_id) { @user.id }

    let(:url) { "#{base_url}/#{@run.id}?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :json, method: :put, status: 202 do
      let(:name) { "put_json_Run" }
      let(:params) { { json_root => { name: name,
                                      owner_id: owner_id,
                                      plan_stage_id: plan_stage_id,
                                      requestor_id: requestor_id,
                                      plan_id: plan_id }  }.to_json }
      let(:updated_run) { Run.where(name: name).first }

      subject { response.body }
      it { should have_json('number.id').with_value(updated_run.id) }
      it { should have_json('string.name').with_value(updated_run.name) }
      it { should have_json('string.aasm_state').with_value(updated_run.aasm_state) }
      it { should have_json('number.owner_id').with_value(updated_run.owner_id) }
      it { should have_json('number.plan_id').with_value(updated_run.plan_id) }
      it { should have_json('number.requestor_id').with_value(updated_run.requestor_id) }
    end

    it_behaves_like 'successful request', type: :xml, method: :put, status: 202 do
      let(:name) { "put_xml_Run" }
      let(:params) { { name: name,
                       owner_id: owner_id,
                       plan_stage_id: plan_stage_id,
                       requestor_id: requestor_id,
                       plan_id: plan_id }.to_xml(root: xml_root)}
      let(:updated_run) { Run.where(name: name).first }

      subject { response.body }
      it { should have_xpath('/run/id').with_text(updated_run.id) }
      it { should have_xpath('/run/name').with_text(updated_run.name) }
      it { should have_xpath('/run/aasm-state').with_text(updated_run.aasm_state) }
      it { should have_xpath('/run/owner-id').with_text(updated_run.owner_id) }
      it { should have_xpath('/run/plan-id').with_text(updated_run.plan_id) }
      it { should have_xpath('/run/requestor-id').with_text(updated_run.requestor_id) }
    end

    it_behaves_like 'editing request with params that fails validation' do
      let(:param) { {:name => nil, :owner_id => nil, :requestor_id => nil, :plan_id => nil } }
    end

    it_behaves_like 'editing request with invalid params'
  end

  describe 'DELETE /v1/runs/[id]' do

    tested_formats.each do |format|
      context 'delete runs' do
        before (:each) { @run = create(:run) }
        let(:url) { "#{base_url}/#{@run.id}/?token=#{@user.api_key}" }
        it_behaves_like "successful request", type: format, method: :delete, status: 202 do
          let(:params) { { } }
          it { Run.find(@run.id).aasm_state.should == 'deleted' }
        end
      end
    end
  end
end