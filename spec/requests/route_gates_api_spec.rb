require 'spec_helper'

base_url = '/v1/route_gates'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :route_gate }
  let(:xml_root) { 'route-gate' }

  before :all do
    @user = create(:user)
    @user.reload
    @token = @user.api_key
  end

  context 'with existing route gates and valid api key' do
    before(:each) do
      @env = create(:environment)
      @route = create(:route)
    end

    let(:url) { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @env_1 = create(:environment)
        @env_2 = create(:environment)

        @route_1 = create(:route)
        @route_2 = create(:route)

        @rg_11 = create(:route_gate, :environment => @env_1, :route => @route_1)
        @rg_12 = create(:route_gate, :environment => @env_1, :route => @route_2)
        @rg_21 = create(:route_gate, :environment => @env_2, :route => @route_1)
        @rg_22 = create(:route_gate, :environment => @env_2, :route => @route_2)
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all route gates' do
          jget

          should have_json(':root > object > number.id').with_values([@rg_11.id, @rg_12.id, @rg_21.id, @rg_22.id])
        end

        it 'should return route gates by environment id' do
          param = {:filters => {:environment_id => @env_1.id}}

          jget param

          should have_json(':root > object > number.id').with_values([@rg_11.id, @rg_12.id])
        end

        it 'should return route gates by route id' do
          param = {:filters => {:route_id => @route_1.id}}

          jget param

          should have_json(':root > object > number.id').with_values([@rg_11.id, @rg_21.id])
        end

        it 'should return route gates by environment id and route id' do
          param = {:filters => {:environment_id => @env_2.id, :route_id => @route_2.id}}

          jget param

          should have_json(':root > object > number.id').with_values([@rg_22.id])
        end
      end

      context 'XML' do
        let(:xml_root) { 'route-gates/route-gate' }
        subject { response.body }

        it 'should return all route gates' do
          xget

          should have_xpath("#{xml_root}/id").with_texts([@rg_11.id, @rg_12.id, @rg_21.id, @rg_22.id])
        end

        it 'should return route gates by environment id' do
          param = {:filters => {:environment_id => @env_1.id}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@rg_11.id, @rg_12.id])
        end

        it 'should return route gates by route id' do
          param = {:filters => {:route_id => @route_1.id}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@rg_11.id, @rg_21.id])
        end

        it 'should return route gates by environment id and route id' do
          param = {:filters => {:environment_id => @env_2.id, :route_id => @route_2.id}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@rg_22.id])
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
        @p_s_i_1 = create(:plan_stage_instance)
        @p_s_i_2 = create(:plan_stage_instance)
        @p_s_i_3 = create(:plan_stage_instance)

        @rg_1 = create(:route_gate)
        @rg_2 = create(:route_gate)

        @c_11 = create(:constraint, :constrainable => @rg_1, :governable => @p_s_i_1)
        @c_12 = create(:constraint, :constrainable => @rg_1, :governable => @p_s_i_2)

        @c_22 = create(:constraint, :constrainable => @rg_2, :governable => @p_s_i_2)
        @c_23 = create(:constraint, :constrainable => @rg_2, :governable => @p_s_i_3)
      end

      context 'JSON' do
        let(:url) { "#{base_url}/#{@rg_1.id}?token=#{@user.api_key}" }

        before(:each) { jget }

        subject { response.body }

        it { should have_json('number.id').with_value(@rg_1.id) }
        it { should have_json('array.constraints > object > number.id').with_values([@c_11.id, @c_12.id]) }
        it { should have_json('array.constraints > object > string.governable_type').with_value('PlanStageInstance') }
        it { should have_json('array.constraints > object > number.governable_id').with_values([@p_s_i_1.id, @p_s_i_2.id]) }
      end

      context 'XML' do
        let(:url) { "#{base_url}/#{@rg_2.id}?token=#{@user.api_key}" }

        before(:each) { xget }

        subject { response.body }

        it { should have_xpath("#{xml_root}/id").with_text(@rg_2.id) }
        it { should have_xpath("#{xml_root}/constraints/constraint/id").with_texts([@c_22.id, @c_23.id]) }
        it { should have_xpath("#{xml_root}/constraints/constraint/governable-type").with_text('PlanStageInstance') }
        it { should have_xpath("#{xml_root}/constraints/constraint/governable-id").with_texts([@p_s_i_2.id, @p_s_i_3.id]) }
      end
    end

    describe "POST #{base_url}" do
      let(:created_route_gate) { RouteGate.last }

      context 'with valid params' do
        let(:param) { {:description => 'Some RouteGate',
                       :different_level_from_previous => false,
                       :environment_id => @env.id,
                       :route_id => @route.id
        }
        }

        context 'JSON' do
          before :each do
            params = {json_root => param}.to_json

            jpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_json('string.created_at') }
          it { should have_json('string.updated_at') }
          it { should have_json('number.id') }
          it { should have_json('number.position') }

          it 'should create route gate with description' do
            should have_json('string.description').with_value('Some RouteGate')
          end

          it 'should create route gate with different_level_from_previous' do
            should have_json('boolean.different_level_from_previous').with_value(false)
          end

          it 'should create route gate with given `environment`' do
            should have_json('object.environment number.id').with_value(@env.id)
            created_route_gate.environment.should == @env
          end

          it 'should create route gate with given `route`' do
            should have_json('object.route number.id').with_value(@route.id)
            created_route_gate.route.should == @route
          end
        end

        context 'XML' do
          before :each do
            params = param.to_xml(:root => xml_root)

            xpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_xpath("#{xml_root}/created-at") }
          it { should have_xpath("#{xml_root}/updated-at") }
          it { should have_xpath("#{xml_root}/id") }
          it { should have_xpath("#{xml_root}/position") }

          it 'should create route gate with description' do
            should have_xpath("#{xml_root}/description").with_text('Some RouteGate')
          end

          it 'should create route gate with different_level_from_previous' do
            should have_xpath("#{xml_root}/different-level-from-previous").with_text(false)
          end

          it 'should create route gate with given `environment`' do
            should have_xpath("#{xml_root}/environment/id").with_text(@env.id)
            created_route_gate.environment.should == @env
          end

          it 'should create route gate with given `route`' do
            should have_xpath("#{xml_root}/route/id").with_text(@route.id)
            created_route_gate.route.should == @route
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        before(:each) { @route_gate = create(:route_gate) }

        let(:param) { {:environment_id => @route_gate.environment_id,
                       :route_id => @route_gate.route_id} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do

      let(:updated_route_gate) { RouteGate.find(@route_gate.id) }
      let(:url) { "#{base_url}/#{@route_gate.id}?token=#{@user.api_key}" }

      context 'with valid params' do
        let(:param) { {:description => 'Some RouteGate',
                       :different_level_from_previous => false,
                       :environment_id => @env.id,
                       :route_id => @route.id
        }
        }

        context 'JSON' do
          before :each do
            params = {json_root => param}.to_json
            @route_gate = create(:route_gate)

            jput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it { should have_json('string.created_at') }
          it { should have_json('string.updated_at') }
          it { should have_json('number.id') }
          it { should have_json('number.position') }

          it 'should create route gate with description' do
            should have_json('string.description').with_value('Some RouteGate')
          end

          it 'should create route gate with different_level_from_previous' do
            should have_json('boolean.different_level_from_previous').with_value(false)
          end

          it 'should create route gate with given `environment`' do
            should have_json('object.environment number.id').with_value(@env.id)
            updated_route_gate.environment.should == @env
          end

          it 'should create route gate with given `route`' do
            should have_json('object.route number.id').with_value(@route.id)
            updated_route_gate.route.should == @route
          end
        end

        context 'XML' do
          before :each do
            params = param.to_xml(:root => xml_root)
            @route_gate = create(:route_gate)

            xput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it { should have_xpath("#{xml_root}/created-at") }
          it { should have_xpath("#{xml_root}/updated-at") }
          it { should have_xpath("#{xml_root}/id") }
          it { should have_xpath("#{xml_root}/position") }

          it 'should create route gate with description' do
            should have_xpath("#{xml_root}/description").with_text('Some RouteGate')
          end

          it 'should create route gate with different_level_from_previous' do
            should have_xpath("#{xml_root}/different-level-from-previous").with_text(false)
          end

          it 'should create route gate with given `environment`' do
            should have_xpath("#{xml_root}/environment/id").with_text(@env.id)
            updated_route_gate.environment.should == @env
          end

          it 'should create route gate with given `route`' do
            should have_xpath("#{xml_root}/route/id").with_text(@route.id)
            updated_route_gate.route.should == @route
          end
        end
      end

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) do
          create(:route_gate)
          @route_gate = create(:route_gate)
        end

        let(:param) { {:environment_id => RouteGate.first.environment_id,
                       :route_id => RouteGate.first.route_id} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @route_gate = create(:route_gate)
      end

      let(:url) { "#{base_url}/#{@route_gate.id}?token=#{@user.api_key}" }

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json = {id: @route_gate.id}.to_json
          params_xml = create_xml { |xml| xml.id @route_gate.id }
          params = eval "params_#{mimetype}"
          mimetype_headers = eval "#{mimetype}_headers"

          delete url, params, mimetype_headers

          response.status.should == 202
        end
      end
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

  context 'with no existing route_gates' do

    let(:token) { @token }

    methods_urls_for_404 = {
        get: ["#{base_url}", "#{base_url}/1"],
        put: ["#{base_url}/1"],
        delete: ["#{base_url}/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_404, :response_code => 404, mimetypes: mimetypes
  end
end