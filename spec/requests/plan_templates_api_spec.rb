require 'spec_helper'

describe '/v1/plan_templates' do
  before :all do
    @user = create(:user)
    User.current_user =  @user
  end

  let(:base_url) { 'v1/plan_templates' }
  let(:params) { {token: @user.api_key} }
  let(:json_root) { :plan_template }
  let(:xml_root) { 'plan-template' }

  describe 'GET /v1/plan_templates' do
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    describe "without filters" do
      before :each do
        @plan_template_1 = create(:plan_template)
        @plan_template_2 = create(:plan_template)
      end

      let(:ids) { [@plan_template_1.id, @plan_template_2.id] }
      let(:names) { [@plan_template_1.name, @plan_template_2.name] }
      let(:template_types) { [@plan_template_1.template_type, @plan_template_2.template_type] }

      it_behaves_like "successful request", type: :json do
        subject { response.body }
        it { should have_json(':root > object > number.id').with_values(ids) }
        it { should have_json(':root > object > string.name').with_values(names) }
        it { should have_json(':root > object > string.template_type').with_values(template_types) }
      end

      it_behaves_like "successful request", type: :xml do
        subject { response.body }
        it { should have_xpath('plan-templates/plan-template/id').with_texts(ids) }
        it { should have_xpath('plan-templates/plan-template/name').with_texts(names) }
        it { should have_xpath('plan-templates/plan-template/template-type').with_texts(template_types) }
      end
    end

    describe "with filters" do
      before :each do
        @plan_template = create(:plan_template)
        @plan_template_archived = create(:plan_template, :aasm_state => 'retired')
        @plan_template_archived.toggle_archive
      end

      let(:archived_id) { @plan_template_archived.id }

      describe "filtered by name" do
        let(:params) { {filters: {name: @plan_template.name }} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan_template.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('plan-templates/plan-template/id').with_text(@plan_template.id) }
        end
      end

      describe "filtered by archived" do
        let(:params) { {filters: {archived: true }} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(archived_id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('plan-templates/plan-template/id').with_text(archived_id) }
        end
      end

      describe "filtered by unarchived" do
        let(:params) { {filters: {unarchived: true }} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan_template.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('plan-templates/plan-template/id').with_text(@plan_template.id) }
        end
      end

      describe "filtered by unarchived + archived" do
        let(:params) { {filters: {unarchived: true, archived: true }} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_values([@plan_template.id, archived_id]) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath('plan-templates/plan-template/id').with_texts([@plan_template.id, archived_id]) }
        end
      end
    end
  end

  describe 'GET /v1/plan_templates/[id]' do
    before(:each) { @plan_template = create(:plan_template) }

    let(:url) { "#{base_url}/#{@plan_template.id}?token=#{@user.api_key}" }

    it_behaves_like "successful request", type: :json do
      subject { response.body }
      it { should have_json('number.id').with_value(@plan_template.id) }
      it { should have_json('string.name').with_value(@plan_template.name) }
      it { should have_json('string.template_type').with_value(@plan_template.template_type) }
    end

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('plan-template/id').with_text(@plan_template.id) }
      it { should have_xpath('plan-template/name').with_text(@plan_template.name) }
      it { should have_xpath('plan-template/template-type').with_text(@plan_template.template_type) }
    end
  end

  describe 'POST /v1/plan_templates' do

    let(:url) { "#{base_url}/?token=#{@user.api_key}" }
    let(:template_type) { 'deploy' }
    let(:is_automatic) { true }

    it_behaves_like "successful request", type: :json, method: :post, status: 201 do
      let(:name) { "JsonPlan Template" }
      let(:params) { { json_root => { name: name, template_type: template_type, is_automatic: is_automatic } }.to_json }
      let(:added_plan_template) { PlanTemplate.where(name: name).first }

      subject { response.body }
      it { should have_json('number.id').with_value(added_plan_template.id) }
      it { should have_json('string.name').with_value(name) }
      it { should have_json('string.template_type').with_value(template_type) }
      it { should have_json('boolean.is_automatic').with_value(is_automatic) }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }
      it { should have_json('*.archive_number') }
      it { should have_json('*.archived_at') }
      it { added_plan_template.name.should == name }
      it { added_plan_template.template_type.should == template_type }
      it { added_plan_template.is_automatic .should == is_automatic }
    end

    it_behaves_like "successful request", type: :xml, method: :post, status: 201 do
      let(:name) { "xmlPlan Template" }
      let(:params) { { name: name, template_type: template_type, is_automatic: is_automatic }.to_xml(root: xml_root) }
      let(:added_plan_template) { PlanTemplate.where(name: name).first }

      subject { response.body }
      it { should have_xpath('plan-template/id').with_text(added_plan_template.id) }
      it { should have_xpath('plan-template/name').with_text(name) }
      it { should have_xpath('plan-template/template-type').with_text(template_type) }
      it { should have_xpath('plan-template/is-automatic').with_text(is_automatic) }
      it { should have_xpath('plan-template/created-at') }
      it { should have_xpath('plan-template/updated-at') }
      it { should have_xpath('plan-template/archive-number') }
      it { should have_xpath('plan-template/archived-at') }
      it { added_plan_template.name.should == name }
      it { added_plan_template.template_type.should == template_type }
      it { added_plan_template.is_automatic .should == is_automatic }
    end

    it_behaves_like 'creating request with params that fails validation' do
      before (:each) { @pt_post = create(:plan_template) }

      let(:param) { {:name => @pt_post.name, :template_type => 'test_deploy'} }
    end

    it_behaves_like 'creating request with invalid params'
  end

  describe 'PUT /v1/plan_templates/[id]' do
    before(:each) { @plan_template = create(:plan_template) }

    let(:url) { "#{base_url}/#{@plan_template.id}?token=#{@user.api_key}" }
    let(:template_type) { 'deploy' }
    let(:is_automatic) { true }

    it_behaves_like "successful request", type: :json, method: :put, status: 202 do
      let(:name) { "put_JsonPlan Template" }
      let(:params) { { json_root => { name: name, template_type: template_type, is_automatic: is_automatic } }.to_json }
      let(:edited_plan_template) { PlanTemplate.where(name: name).first }

      subject { response.body }
      it { should have_json('number.id').with_value(edited_plan_template.id) }
      it { should have_json('string.name').with_value(name) }
      it { should have_json('string.template_type').with_value(template_type) }
      it { should have_json('boolean.is_automatic').with_value(is_automatic) }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }
      it { should have_json('*.archive_number') }
      it { should have_json('*.archived_at') }
      it { edited_plan_template.name.should == name }
      it { edited_plan_template.template_type.should == template_type }
      it { edited_plan_template.is_automatic .should == is_automatic }
    end

    it_behaves_like "successful request", type: :xml, method: :put, status: 202 do
      let(:name) { "put_xmlPlan Template" }
      let(:params) { { name: name, template_type: template_type, is_automatic: is_automatic }.to_xml(root: xml_root) }
      let(:edited_plan_template) { PlanTemplate.where(name: name).first }

      subject { response.body }
      it { should have_xpath('plan-template/id').with_text(edited_plan_template.id) }
      it { should have_xpath('plan-template/name').with_text(name) }
      it { should have_xpath('plan-template/template-type').with_text(template_type) }
      it { should have_xpath('plan-template/is-automatic').with_text(is_automatic) }
      it { should have_xpath('plan-template/created-at') }
      it { should have_xpath('plan-template/updated-at') }
      it { should have_xpath('plan-template/archive-number') }
      it { should have_xpath('plan-template/archived-at') }
      it { edited_plan_template.name.should == name }
      it { edited_plan_template.template_type.should == template_type }
      it { edited_plan_template.is_automatic .should == is_automatic }
    end

    it_behaves_like 'editing request with params that fails validation' do
      before :each do
        create(:plan_template)
        @pt_put = create(:plan_template)
      end

      let(:url) { "#{base_url}/#{@pt_put.id}?token=#{@user.api_key}" }
      let(:param) { { :name => PlanTemplate.first.name } }
    end

    it_behaves_like 'editing request with invalid params'

    it_behaves_like 'with `toggle_archive` param'
  end

  describe 'DELETE /v1/plan_templates/[id]' do

    tested_formats.each do |type|
      context 'when trying to delete non-archived plan_template' do
        before(:each) { @plan_template = create(:plan_template) }
        let(:url) { "#{base_url}/#{@plan_template.id}/?token=#{@user.api_key}" }
        it_behaves_like "successful request", type: type, method: :delete, status: 412 do
          let(:params) { {} }
          it { PlanTemplate.exists?(@plan_template.id).should be_truthy }
        end
      end
    end

    tested_formats.each do |type|
      context 'when trying to delete archived plan_template' do
        before (:each) { @plan_template = create(:plan_template, :aasm_state => 'retired') { |plan_template| plan_template.toggle_archive } }
        let(:url) { "#{base_url}/#{@plan_template.id}/?token=#{@user.api_key}" }
        it_behaves_like "successful request", type: type, method: :delete, status: 202 do
          let(:params) { {} }
          it { PlanTemplate.exists?(@plan_template.id).should be_falsey }
        end
      end
    end
  end
end