require 'spec_helper'

describe 'plan_stages' do
  before :all do
    @user = create(:user)
    User.current_user =  @user
  end

  let(:base_url) { 'v1/plan_stages' }
  let(:json_root) { :plan_stage }
  let(:xml_root) { 'plan_stage' }
  let(:params) { {token: @user.api_key} }

  describe 'GET /v1/plan_stages' do
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    before :each do
      @plan_stage_1 = create(:plan_stage)
      @plan_stage_2 = create(:plan_stage)
    end

    let(:ids) { [@plan_stage_1.id, @plan_stage_2.id] }
    let(:positions) { [@plan_stage_1.position, @plan_stage_2.position] }
    let(:names) { [@plan_stage_1.name, @plan_stage_2.name] }
    let(:plan_template_ids) { [@plan_stage_1.plan_template.id, @plan_stage_2.plan_template.id] }
    let(:plan_template_names) { [@plan_stage_1.plan_template.name, @plan_stage_2.plan_template.name] }
    let(:environment_type_ids) { [@plan_stage_1.environment_type.id, @plan_stage_2.environment_type.id] }
    let(:environment_type_names) { [@plan_stage_1.environment_type.name, @plan_stage_2.environment_type.name] }

    it_behaves_like "successful request", type: :json do
      subject { response.body }
      it { should have_json(':root > object > number.id').with_values(ids) }
      it { should have_json(':root > object > number.position').with_values(positions) }
      it { should have_json(':root > object > string.name').with_values(names) }
      it { should have_json(':root > object > object.plan_template > number.id').with_values(plan_template_ids) }
      it { should have_json(':root > object > object.plan_template > string.name').with_values(plan_template_names) }
      it { should have_json(':root > object > object.environment_type > number.id').with_values(environment_type_ids) }
      it { should have_json(':root > object > object.environment_type > string.name').with_values(environment_type_names) }
    end

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('plan-stages/plan-stage/id').with_texts(ids) }
      it { should have_xpath('plan-stages/plan-stage/position').with_texts(positions) }
      it { should have_xpath('plan-stages/plan-stage/name').with_texts(names) }
      it { should have_xpath('plan-stages/plan-stage/plan-template/id').with_texts(plan_template_ids) }
      it { should have_xpath('plan-stages/plan-stage/plan-template/name').with_texts(plan_template_names) }
      it { should have_xpath('plan-stages/plan-stage/environment-type/id').with_texts(environment_type_ids) }
      it { should have_xpath('plan-stages/plan-stage/environment-type/name').with_texts(environment_type_names) }
    end

  end

  describe 'GET /v1/plan_stages/[id]' do
    before (:each) { @plan_stage = create(:plan_stage) }

    let(:url) { "#{base_url}/#{@plan_stage.id}?token=#{@user.api_key}" }

    it_behaves_like "successful request", type: :json do
      subject { response.body }
      it { should have_json('number.id').with_value(@plan_stage.id) }
      it { should have_json('number.position').with_value(@plan_stage.position) }
      it { should have_json('string.name').with_value(@plan_stage.name) }
      it { should have_json('object.plan_template > number.id').with_value(@plan_stage.plan_template_id) }
      it { should have_json('object.plan_template > string.name').with_value(@plan_stage.plan_template.name) }
      it { should have_json('object.environment_type > number.id').with_value(@plan_stage.environment_type_id) }
      it { should have_json('object.environment_type > string.name').with_value(@plan_stage.environment_type.name) }
    end

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('plan-stage/id').with_text(@plan_stage.id) }
      it { should have_xpath('plan-stage/position').with_text(@plan_stage.position) }
      it { should have_xpath('plan-stage/name').with_text(@plan_stage.name) }
      it { should have_xpath('plan-stage/plan-template/id').with_text(@plan_stage.plan_template_id) }
      it { should have_xpath('plan-stage/plan-template/name').with_text(@plan_stage.plan_template.name) }
      it { should have_xpath('plan-stage/environment-type/id').with_text(@plan_stage.environment_type_id) }
      it { should have_xpath('plan-stage/environment-type/name').with_text(@plan_stage.environment_type.name) }
    end
  end

  describe 'POST /v1/plan_stages' do
    before(:each) do
      @plan_template = create(:plan_template)
      @environment_type = create(:environment_type)
    end

    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    let(:plan_template_id) { @plan_template.id }
    let(:environment_type_id) { @environment_type.id }
    let(:position) { 2 }

    it_behaves_like "successful request", type: :json, method: :post, status: 201 do
      let(:name) { "json Plan Stage" }
      let(:params) { { json_root => { name: name,
                                      plan_template_id: plan_template_id,
                                      environment_type_id: environment_type_id,
                                      position: position } }.to_json }
      let(:added_plan_stage) { PlanStage.where(name: name).first }

      subject { response.body }
      it { should have_json('number.id').with_value(added_plan_stage.id) }
      it { should have_json('number.position').with_value(added_plan_stage.position) }
      it { should have_json('string.name').with_value(added_plan_stage.name) }
      it { should have_json('object.plan_template > number.id').with_value(added_plan_stage.plan_template_id) }
      it { should have_json('object.environment_type > number.id').with_value(added_plan_stage.environment_type_id) }
    end

    it_behaves_like "successful request", type: :xml, method: :post, status: 201 do
      let(:name) { "xml Plan Stage" }
      let(:params) { { name: name,
                       plan_template_id: plan_template_id,
                       environment_type_id: environment_type_id,
                       position: position }.to_xml(root: xml_root) }
      let(:added_plan_stage) { PlanStage.where(name: name).first }

      subject { response.body }
      it { should have_xpath('plan-stage/id').with_text(added_plan_stage.id) }
      it { should have_xpath('plan-stage/position').with_text(added_plan_stage.position) }
      it { should have_xpath('plan-stage/name').with_text(added_plan_stage.name) }
      it { should have_xpath('plan-stage/plan-template/id').with_text(added_plan_stage.plan_template_id) }
      it { should have_xpath('plan-stage/environment-type/id').with_text(added_plan_stage.environment_type_id) }
    end

    it_behaves_like 'creating request with params that fails validation' do
      let(:param) { { :name => nil, :plan_template_id => nil } }
    end

    it_behaves_like 'creating request with invalid params'
  end

  describe 'PUT /v1/plan_stages/[id]' do
    before(:each) do
      @plan_template = create(:plan_template)
      @environment_type = create(:environment_type)
      @plan_stage = create(:plan_stage)
    end

    let(:url) { "#{base_url}/#{@plan_stage.id}?token=#{@user.api_key}" }

    let(:plan_template_id) { @plan_template.id }
    let(:environment_type_id) { @environment_type.id }
    let(:position) { 2 }

    it_behaves_like "successful request", type: :json, method: :put, status: 202 do
      let(:name) { "put_json Plan Stage" }
      let(:params) { { json_root => { name: name,
                                      plan_template_id: plan_template_id,
                                      environment_type_id: environment_type_id,
                                      position: position } }.to_json }
      let(:updated_plan_stage) { PlanStage.where(name: name).first }

      subject { response.body }
      it { should have_json('number.id').with_value(updated_plan_stage.id) }
      it { should have_json('number.position').with_value(updated_plan_stage.position) }
      it { should have_json('string.name').with_value(updated_plan_stage.name) }
      it { should have_json('object.plan_template > number.id').with_value(updated_plan_stage.plan_template_id) }
      it { should have_json('object.environment_type > number.id').with_value(updated_plan_stage.environment_type_id) }
    end

    it_behaves_like "successful request", type: :xml, method: :put, status: 202 do
      let(:name) { "put_xml Plan Stage" }
      let(:params) { { name: name,
                       plan_template_id: plan_template_id,
                       environment_type_id: environment_type_id,
                       position: position }.to_xml(root: xml_root) }
      let(:updated_plan_stage) { PlanStage.where(name: name).first }

      subject { response.body }
      it { should have_xpath('plan-stage/id').with_text(updated_plan_stage.id) }
      it { should have_xpath('plan-stage/position').with_text(updated_plan_stage.position) }
      it { should have_xpath('plan-stage/name').with_text(updated_plan_stage.name) }
      it { should have_xpath('plan-stage/plan-template/id').with_text(updated_plan_stage.plan_template_id) }
      it { should have_xpath('plan-stage/environment-type/id').with_text(updated_plan_stage.environment_type_id) }
    end

    it_behaves_like 'editing request with params that fails validation' do
      let(:param) { { :name => nil } }
    end

    it_behaves_like 'editing request with invalid params'
  end

  describe 'DELETE /v1/plan_stages/[id]' do

    tested_formats.each do |format|
      context 'delete plan_stage' do
        before (:each) { @plan_stage = create(:plan_stage) }
        let(:url) { "#{base_url}/#{@plan_stage.id}/?token=#{@user.api_key}" }
        it_behaves_like "successful request", type: format, method: :delete, status: 202 do
          let(:params) { { } }
          it { PlanStage.exists?(@plan_stage.id).should be_falsey }
        end
      end
    end
  end
end