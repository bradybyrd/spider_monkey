require 'spec_helper'

describe '/v1/plans' do
  before :all do
    @user = create(:user)
    User.current_user =  @user
  end

  let(:base_url) { 'v1/plans' }
  let(:json_root) { :plan }
  let(:xml_root) { 'plan' }
  let(:params) { {token: @user.api_key} }

  describe 'GET /v1/plans' do

    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    let(:xml_root) { 'plans/plan' }

    describe "without filters" do
      before :each do
        @plan_1 = create(:plan)
        @plan_2 = create(:plan)
        @plan_1.reload
        @plan_2.reload
        @user.reload
      end

      let(:ids) { [@plan_1.id, @plan_2.id] }
      let(:plan_template_ids) { [@plan_1.plan_template.id, @plan_2.plan_template.id] }
      let(:plan_template_names) { [@plan_1.plan_template.name, @plan_2.plan_template.name] }
      let(:names) { [@plan_1.name, @plan_2.name] }
      let(:descriptions) { [@plan_1.description, @plan_2.description] }

      it_behaves_like "successful request", type: :json do
        subject { response.body }
        it { should have_json(':root > object > number.id').with_values(ids) }
        it { should have_json(':root > object > string.name').with_values(names) }
        it { should have_json(':root > object > string.description').with_values(descriptions) }
        it { should have_json(':root > object > object.plan_template > number.id').with_values(plan_template_ids) }
        it { should have_json(':root > object > object.plan_template > string.name').with_values(plan_template_names) }
        it { should have_json(':root > object > string.release_date') }
      end

      it_behaves_like "successful request", type: :xml do
        subject { response.body }
        it { should have_xpath("#{xml_root}/id").with_texts(ids) }
        it { should have_xpath("#{xml_root}/name").with_texts(names) }
        it { should have_xpath("#{xml_root}/description").with_texts(descriptions) }
        it { should have_xpath("#{xml_root}/plan-template/id").with_texts(plan_template_ids) }
        it { should have_xpath("#{xml_root}/plan-template/name").with_texts(plan_template_names) }
        it { should have_xpath("#{xml_root}/release-date") }
      end
    end

    describe "with filters" do
      before :each do
        @project_server = create(:project_server)
        @release_manager = create(:user)
        @plan = create(:plan, :foreign_id => "2", :project_server => @project_server, :release_id => 1001, :release_manager => @release_manager)
        @team = create(:team)
        @plan_team = create(:plan_team, :plan => @plan, :team => @team)
        @stage = create(:plan_stage, :plan_template => @plan.plan_template )
        @plan_member = create(:plan_member, :plan => @plan)
        @environment = create(:environment)
        @request = create(:request , :plan_member => @plan_member, :environment => @environment)
        @apps_request = create(:apps_request, :request => @request)
        @plan.reload
        @user.reload
      end

      describe "filtered by aasm_state" do
        let(:params) { {filters: {aasm_state: @plan.aasm_state}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@plan.id) }
        end
      end

      describe "filtered by name" do
        let(:params) { {filters: {name: @plan.name}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@plan.id) }
        end
      end

      describe "filtered by plan_template_id" do
        let(:params) { {filters: {plan_template_id: @plan.plan_template_id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@plan.id) }
        end
      end

      describe "filtered by release_date" do
        let(:params) { {filters: {release_date: @plan.release_date}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@plan.id) }
        end
      end

      describe "filtered by foreign_id" do
        let(:params) { {filters: {foreign_id: @plan.foreign_id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@plan.id) }
        end
      end

      describe "filtered by project_server_id" do
        let(:params) { {filters: {project_server_id: @plan.project_server_id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@plan.id) }
        end
      end

      describe "filtered by app_id" do
        let(:params) { {filters: {app_id: @apps_request.app_id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@plan.id) }
        end
      end

      describe "filtered by environment_id" do
        let(:params) { {filters: {environment_id: @request.environment.id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@plan.id) }
        end
      end

      describe "filtered by plan_type" do
        let(:params) { {filters: {plan_type: @plan.plan_template.template_type}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@plan.id) }
        end
      end

      describe "filtered by release_id" do
        let(:params) { {filters: {release_id: @plan.release_id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@plan.id) }
        end
      end

      describe "filtered by release_manager_id" do
        let(:params) { {filters: {release_manager_id: @plan.release_manager.id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@plan.id) }
        end
      end

      describe "filtered by stage_id" do
        let(:params) { {filters: {stage_id: @stage.id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@plan.id) }
        end
      end

      describe "filtered by team_id" do
        let(:params) { {filters: {team_id: @team.id}} }

        it_behaves_like "successful request", type: :json do
          it { response.body.should have_json('number.id').with_value(@plan.id) }
        end

        it_behaves_like "successful request", type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@plan.id) }
        end
      end
    end
  end

  describe 'GET /v1/plans/[id]' do
    before (:each) do
      @plan_stage_1 = create(:plan_stage)
      @plan_stage_2 = create(:plan_stage)
      @plan_template = create(:plan_template, :stages => [@plan_stage_1, @plan_stage_2])
      @plan = create(:plan, :plan_template => @plan_template)
      @route_1 = create(:route, :description => "Route #1")
      @route_2 = create(:route, :description => "Route #2")
      @plan_route_1 = create(:plan_route, :plan => @plan, :route => @route_1)
      @plan_route_2 = create(:plan_route, :plan => @plan, :route => @route_2)
      @user.reload

      @psi_id = []
      @psi_aasm_state = []
      @psi_ps_id = []
      @psi_ps_name = []
      @plan.plan_stage_instances.each do |psi|
        @psi_id << psi.id
        @psi_aasm_state << psi.aasm_state
        @psi_ps_id << psi.plan_stage.id
        @psi_ps_name << psi.plan_stage.name
      end
    end

    let(:url) { "#{base_url}/#{@plan.id}?token=#{@user.api_key}" }

    it_behaves_like "successful request", type: :json do
      subject { response.body }
      it { should have_json('number.id').with_value(@plan.id) }
      it { should have_json('string.name').with_value(@plan.name) }
      it { should have_json('string.description').with_value(@plan.description) }
      it { should have_json('object.plan_template > number.id').with_value(@plan.plan_template_id) }
      it { should have_json('object.plan_template > string.name').with_value(@plan.plan_template_name) }
      it { should have_json('string.release_date') }

      it { should have_json('array.plan_routes > object > number.id').with_values([@plan_route_1.id, @plan_route_2.id]) }
      it { should have_json('array.plan_routes > object > object.route > number.id').with_values([@route_1.id, @route_2.id]) }
      it { should have_json('array.plan_routes > object > object.route > string.name').with_values([@route_1.name, @route_2.name]) }
      it { should have_json('array.plan_routes > object > object.route > string.description').with_values([@route_1.description, @route_2.description]) }
      it { should have_json('array.plan_routes > object > object.route > string.route_type').with_values([@route_1.route_type, @route_2.route_type]) }

      it { should have_json('array.plan_stage_instances > object > number.id').with_values(@psi_id) }
      it { should have_json('array.plan_stage_instances > object > string.aasm_state').with_values(@psi_aasm_state) }
      it { should have_json('array.plan_stage_instances > object > object.plan_stage > number.id').with_values(@psi_ps_id) }
      it { should have_json('array.plan_stage_instances > object > object.plan_stage > string.name').with_values(@psi_ps_name) }
    end

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(@plan.id) }
      it { should have_xpath("#{xml_root}/name").with_text(@plan.name) }
      it { should have_xpath("#{xml_root}/description").with_text(@plan.description) }
      it { should have_xpath("#{xml_root}/plan-template/id").with_text(@plan.plan_template_id) }
      it { should have_xpath("#{xml_root}/plan-template/name").with_text(@plan.plan_template.name) }
      it { should have_xpath("#{xml_root}/release-date") }

      it { should have_xpath("#{xml_root}/plan-routes/plan-route/id").with_texts([@plan_route_1.id, @plan_route_2.id]) }
      it { should have_xpath("#{xml_root}/plan-routes/plan-route/route/id").with_texts([@route_1.id, @route_2.id]) }
      it { should have_xpath("#{xml_root}/plan-routes/plan-route/route/name").with_texts([@route_1.name, @route_2.name]) }
      it { should have_xpath("#{xml_root}/plan-routes/plan-route/route/description").with_texts([@route_1.description, @route_2.description]) }
      it { should have_xpath("#{xml_root}/plan-routes/plan-route/route/route-type").with_texts([@route_1.route_type, @route_2.route_type]) }

      it { should have_xpath("#{xml_root}/plan-stage-instances/plan-stage-instance/id").with_texts(@psi_id) }
      it { should have_xpath("#{xml_root}/plan-stage-instances/plan-stage-instance/aasm-state").with_texts(@psi_aasm_state) }
      it { should have_xpath("#{xml_root}/plan-stage-instances/plan-stage-instance/plan-stage/id").with_texts(@psi_ps_id) }
      it { should have_xpath("#{xml_root}/plan-stage-instances/plan-stage-instance/plan-stage/name").with_texts(@psi_ps_name) }
    end
  end

  describe 'POST /v1/plans' do

    let(:url) { "#{base_url}/?token=#{@user.api_key}" }
    let(:plan_template) { create(:plan_template)  }
    let(:plan_template_id) { plan_template.id }
    let(:plan_template_name)  { plan_template.name }
    let(:description)  { "description" }

    it_behaves_like "successful request", type: :json, method: :post, status: 201 do
      let(:name) { "json_Plan #{Time.now.to_i}" }
      let(:params) { { json_root => { name: name,
                                      plan_template_id: plan_template.id,
                                      description: 'A sample description.' } }.to_json }
      let(:added_plan) { Plan.where(name: name).first }

      subject { response.body }
      it { should have_json('number.id').with_value(added_plan.id) }
      it { should have_json('string.name').with_value(added_plan.name) }
      it { should have_json('string.description').with_value(added_plan.description) }
      it { should have_json('object.plan_template > number.id').with_value(added_plan.plan_template_id) }
      it { should have_json('object.plan_template > string.name').with_value(added_plan.plan_template_name) }
    end

    it_behaves_like "successful request", type: :xml, method: :post, status: 201 do
      let(:name) { "xml_Plan #{Time.now.to_i}" }
      let(:params) { { name: name,
                       plan_template_id: plan_template_id,
                       description: description }.to_xml(root: xml_root) }
      let(:added_plan) { Plan.where(name: name).first }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_plan.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_plan.name) }
      it { should have_xpath("#{xml_root}/description").with_text(added_plan.description) }
      it { should have_xpath("#{xml_root}/plan-template/id").with_text(added_plan.plan_template_id) }
      it { should have_xpath("#{xml_root}/plan-template/name").with_text(added_plan.plan_template.name) }
    end

    it_behaves_like 'creating request with params that fails validation' do
      let(:param) { { name: nil, plan_template_id: nil } }
    end

    it_behaves_like 'creating request with invalid params'
  end

  describe 'PUT /v1/plans/[id]' do
    before(:each) do
      @plan_template = create(:plan_template)
      @plan = create(:plan)
      @user.reload
      @plan.reload
    end

    let(:url) { "#{base_url}/#{@plan.id}?token=#{@user.api_key}" }

    let(:plan_template_id) { @plan_template.id }
    let(:plan_template_name)  { @plan_template.name }
    let(:description)  { "description" }

    it_behaves_like "successful request", type: :json, method: :put, status: 202 do
      let(:name) { "put_json_Plan" }
      let(:params) { { json_root => { name: name,
                                      plan_template_id: plan_template_id,
                                      plan_template_name: plan_template_name,
                                      description: description } }.to_json }
      let(:updated_plan) { Plan.where(name: name).first }

      subject { response.body }
      it { should have_json('number.id').with_value(updated_plan.id) }
      it { should have_json('string.name').with_value(updated_plan.name) }
      it { should have_json('string.description').with_value(updated_plan.description) }
      it { should have_json('object.plan_template > number.id').with_value(updated_plan.plan_template_id) }
      it { should have_json('object.plan_template > string.name').with_value(updated_plan.plan_template_name) }
    end

    it_behaves_like "successful request", type: :xml, method: :put, status: 202 do
      let(:name) { "put_xml_Plan" }
      let(:params) { { name: name,
                       plan_template_id: plan_template_id,
                       plan_template_name: plan_template_name,
                       description: description }.to_xml(root: xml_root) }
      let(:updated_plan) { Plan.where(name: name).first }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(updated_plan.id) }
      it { should have_xpath("#{xml_root}/name").with_text(updated_plan.name) }
      it { should have_xpath("#{xml_root}/description").with_text(updated_plan.description) }
      it { should have_xpath("#{xml_root}/plan-template/id").with_text(updated_plan.plan_template_id) }
      it { should have_xpath("#{xml_root}/plan-template/name").with_text(updated_plan.plan_template.name) }
    end

    it_behaves_like 'editing request with params that fails validation' do
      let(:param) { {:name => ''} }
    end

    it_behaves_like 'editing request with invalid params'
  end

  describe 'DELETE /v1/plans/[id]' do

    tested_formats.each do |format|
      context 'delete plans' do
        before (:each) { @plan = create(:plan) }
        let(:url) { "#{base_url}/#{@plan.id}/?token=#{@user.api_key}" }
        it_behaves_like "successful request", type: format, method: :delete, status: 202 do
          let(:params) { { } }
          it { Plan.find(@plan.id).aasm_state.should == 'deleted' }
        end
      end
    end
  end
end