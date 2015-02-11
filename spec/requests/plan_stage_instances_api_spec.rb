require 'spec_helper'

base_url = '/v1/plan_stage_instances'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :plan_stage_instance }
  let(:xml_root) { 'plan-stage-instance' }

  before :all do
    @user = create(:user)
    @token = @user.api_key
  end

  context 'with existing plan_stage_instance and valid api key' do

    let(:url) { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        PlanStageInstance.delete_all
        @plan_template_1 = create(:plan_template)
        @plan_stage_1 = create(:plan_stage, :plan_template => @plan_template_1)
        @plan_stage_2 = create(:plan_stage, :plan_template => @plan_template_1)
        @plan_template_2 = create(:plan_template)
        @plan_stage_3 = create(:plan_stage, :plan_template => @plan_template_2)
        @plan_1 = create(:plan, :plan_template => @plan_template_1)
        @plan_2 = create(:plan, :plan_template => @plan_template_1)
        @plan_3 = create(:plan, :plan_template => @plan_template_2)

        @plan_stage_instance_1 = @plan_1.plan_stage_instances.first
        @plan_stage_instance_2 = @plan_2.plan_stage_instances.first
        @plan_stage_instance_2.archive
        @plan_stage_instance_3 = @plan_3.plan_stage_instances.first

        @unarchived_ids = PlanStageInstance.unarchived.all.map { |e| e.id }
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all plan stage instances except archived(by default)' do
          jget

          should have_json(':root > object > number.id').with_values(@unarchived_ids)
        end

        it 'should return all plan stage instances except archived' do
          param = {:filters => {:unarchived => true}}

          jget param

          should have_json(':root > object > number.id').with_values(@unarchived_ids)
        end

        it 'should return all plan stage instances archived' do
          param = {:filters => {:archived => true}}

          jget param

          should have_json(':root > object > number.id').with_value(@plan_stage_instance_2.id)
        end

        it 'should return all plan stage instances' do
          param = {:filters => {:archived => true, :unarchived => true}}

          jget param

          should have_json(':root > object > number.id').with_values([@plan_stage_instance_2.id] + @unarchived_ids)
        end

        it 'should return all archived plan stage instances' do
          param = {:filters => {:archived => true, :unarchived => false}}

          jget param

          should have_json(':root > object > number.id').with_value(@plan_stage_instance_2.id)
        end

        it 'should return plan stage instance by plan and plan stage' do
          param = {:filters => {:plan_id => @plan_stage_instance_1.plan_id,
                                :plan_stage_id => @plan_stage_instance_1.plan_stage_id}}

          jget param

          should have_json(':root > object > number.id').with_value(@plan_stage_instance_1.id)
        end

        it 'should not return archived plan stage instances by plan and plan stage' do
          param = {:filters => {:plan_id => @plan_stage_instance_2.plan_id,
                                :plan_stage_id => @plan_stage_instance_2.plan_stage_id}}

          jget param

          should == " "
        end

        it 'should return archived plan stage instance by plan and plan stage if it is specified' do
          param = {:filters => {:plan_id => @plan_stage_instance_2.plan_id,
                                :plan_stage_id => @plan_stage_instance_2.plan_stage_id,
                                :archived => true}}

          jget param

          should have_json(':root > object > number.id').with_value(@plan_stage_instance_2.id)
        end
      end

      context 'XML' do
        let(:xml_root) { 'plan-stage-instances/plan-stage-instance' }
        subject { response.body }

        it 'should return all plan stage instances except archived(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_ids)
        end

        it 'should return all plan stage instances except archived' do
          param = {:filters => {:unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_ids)
        end

        it 'should return all plan stage instances archived' do
          param = {:filters => {:archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@plan_stage_instance_2.id)
        end

        it 'should return all plan stage instances' do
          param = {:filters => {:archived => true, :unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@plan_stage_instance_2.id] + @unarchived_ids)
        end

        it 'should return all archived plan stage instances' do
          param = {:filters => {:archived => true, :unarchived => false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@plan_stage_instance_2.id)
        end

        it 'should return plan stage instance by plan and plan stage' do
          param = {:filters => {:plan_id => @plan_stage_instance_1.plan_id,
                                :plan_stage_id => @plan_stage_instance_1.plan_stage_id}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@plan_stage_instance_1.id)
        end

        it 'should not return archived plan stage instances by plan and plan stage' do
          param = {:filters => {:plan_id => @plan_stage_instance_2.plan_id,
                                :plan_stage_id => @plan_stage_instance_2.plan_stage_id}}

          xget param

          should == " "
        end

        it 'should return archived plan stage instance by plan and plan stage if it is specified' do
          param = {:filters => {:plan_id => @plan_stage_instance_2.plan_id,
                                :plan_stage_id => @plan_stage_instance_2.plan_stage_id,
                                :archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@plan_stage_instance_2.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:all) do
        # without this, it is difficult to get a plan assigned without two copies
        # of the plan stage instance
        Plan.skip_callback(:create, :after, :build_plan_stage_instances)
      end

      after(:all) do
        # without this, it is difficult to get a plan assigned without two copies
        # of the plan stage instance
        Plan.set_callback(:create, :after, :build_plan_stage_instances)
      end

      before(:each) do

        @plan_stage_instance_1 = create(:plan_stage_instance)
        @plan_stage_instance_2 = create(:plan_stage_instance)

        @route_gate_1 = create(:route_gate)
        @route_gate_2 = create(:route_gate)
        @route_gate_3 = create(:route_gate)

        @constraint_11 = create(:constraint, :governable => @plan_stage_instance_1, :constrainable => @route_gate_1)
        @constraint_12 = create(:constraint, :governable => @plan_stage_instance_1, :constrainable => @route_gate_2)

        @constraint_22 = create(:constraint, :governable => @plan_stage_instance_2, :constrainable => @route_gate_2)
        @constraint_23 = create(:constraint, :governable => @plan_stage_instance_2, :constrainable => @route_gate_3)
      end

      context 'JSON' do
        let(:url) { "#{base_url}/#{@plan_stage_instance_1.id}?token=#{@user.api_key}" }

        before(:each) { jget }

        subject { response.body }

        it { should have_json('number.id').with_value(@plan_stage_instance_1.id) }
        it { should have_json('array.constraints > object > number.id').with_values([@constraint_11.id, @constraint_12.id]) }
        it { should have_json('array.constraints > object > string.constrainable_type').with_value('RouteGate') }
        it { should have_json('array.constraints > object > number.constrainable_id').with_values([@route_gate_1.id, @route_gate_2.id]) }
      end

      context 'XML' do
        let(:url) { "#{base_url}/#{@plan_stage_instance_2.id}?token=#{@user.api_key}" }

        before(:each) { xget }

        subject { response.body }

        it { should have_xpath("#{xml_root}/id").with_text(@plan_stage_instance_2.id) }
        it { should have_xpath("#{xml_root}/constraints/constraint/id").with_texts([@constraint_22.id, @constraint_23.id]) }
        it { should have_xpath("#{xml_root}/constraints/constraint/constrainable-type").with_text('RouteGate') }
        it { should have_xpath("#{xml_root}/constraints/constraint/constrainable-id").with_texts([@route_gate_2.id, @route_gate_3.id]) }
      end
    end

    describe "POST PUT DELETE #{base_url}" do
      let(:token) { @token }

      methods_urls_for_405 = {
          post:     ["#{base_url}"],
          put:      ["#{base_url}/1"],
          delete:   ["#{base_url}/1"]
      }

      mimetypes = ['json', 'xml']

      test_batch_of_requests methods_urls_for_405, :response_code => 405, :mimetypes => mimetypes
    end
  end

  context 'with invalid api key' do
    let(:token) { 'invalid_api_key' }

    methods_urls_for_403 = {
        get: ["#{base_url}", "#{base_url}/1"],
        post: ["#{base_url}"],
        put: ["#{base_url}/1"],
        delete: ["#{base_url}/1"]
    }

    test_batch_of_requests methods_urls_for_403, :response_code => 403
  end

  context 'with no existing plan stage instances' do
    before :each do
      # make sure there's none of plan stage instancess
      PlanStageInstance.delete_all
    end

    let(:token) { @token }

    methods_urls_for_404 = {
        get: ["#{base_url}", "#{base_url}/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_404, :response_code => 404, mimetypes: mimetypes
  end
end
