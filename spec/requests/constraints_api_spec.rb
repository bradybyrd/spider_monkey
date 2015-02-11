require 'spec_helper'

base_url =  '/v1/constraints'
describe "testing #{base_url}" do
  let(:base_url)  { base_url }
  let(:json_root) { :constraint }
  let(:xml_root)  { 'constraint' }

  before :each do
    @user         = create(:user)
    @token        = @user.api_key
  end

  context 'with existing constraint and valid api key' do

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do

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
        @c_13 = create(:constraint, :constrainable => @rg_1, :governable => @p_s_i_3, :active => false)

        @c_21 = create(:constraint, :constrainable => @rg_2, :governable => @p_s_i_1, :active => false)
        @c_22 = create(:constraint, :constrainable => @rg_2, :governable => @p_s_i_2)
        @c_23 = create(:constraint, :constrainable => @rg_2, :governable => @p_s_i_3)

        @active_ids = [@c_11.id, @c_12.id, @c_22.id, @c_23.id]
        @inactive_ids = [@c_13.id, @c_21.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all constraints except inactive(by default)' do
          jget

          should have_json('number.id').with_values(@active_ids)
        end

        it 'should return all constraints except inactive' do
          param   = {:filters => {:active => true}}

          jget param

          should have_json('number.id').with_values(@active_ids)
        end

        it 'should return all constraints inactive' do
          param   = {:filters => {:inactive => true}}

          jget param

          should have_json('number.id').with_values(@inactive_ids)
        end

        it 'should return all constraints' do
          param   = {:filters => {:inactive => true, :active => true}}

          jget param

          should have_json('number.id').with_values(@active_ids + @inactive_ids)
        end

        it 'should return all inactive constraints' do
          param   = {:filters => {:inactive => true, :active => false}}

          jget param

          should have_json('number.id').with_values(@inactive_ids)
        end

        it 'should return constraint by constrainable and governable' do
          param   = {:filters => {:constraint => {:id => @rg_2.id, :type => 'RouteGate'},
                                  :governor => {:id => @p_s_i_2.id, :type => 'PlanStageInstance'}}}

          jget param

          should have_json('number.id').with_value(@c_22.id)
        end

        it 'should not return inactive constraint by constrainable and governable' do
          param   = {:filters => {:constraint => {:id => @rg_1.id, :type => 'RouteGate'},
                                  :governor => {:id => @p_s_i_3.id, :type => 'PlanStageInstance'}}}

          jget param

          should == " "
        end

        it 'should return inactive constraint by constrainable and governable if it is specified' do
          param   = {:filters => {:constraint => {:id => @rg_1.id, :type => 'RouteGate'},
                                  :governor => {:id => @p_s_i_3.id, :type => 'PlanStageInstance'},
                                  :inactive => true}}

          jget param

          should have_json('number.id').with_value(@c_13.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'constraints/constraint'}
        subject { response.body }

        it 'should return all constraints except inactive(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@active_ids)
        end

        it 'should return all constraints except inactive' do
          param   = {:filters => {:active => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@active_ids)
        end

        it 'should return all constraints inactive' do
          param   = {:filters => {:inactive => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@inactive_ids)
        end

        it 'should return all constraints' do
          param   = {:filters => {:inactive => true, :active => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@active_ids + @inactive_ids)
        end

        it 'should return all inactive constraints' do
          param   = {:filters => {:inactive => true, :active => false}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@inactive_ids)
        end

        it 'should return constraint by constrainable and governable' do
          param   = {:filters => {:constraint => {:id => @rg_2.id, :type => 'RouteGate'},
                                  :governor => {:id => @p_s_i_2.id, :type => 'PlanStageInstance'}}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@c_22.id)
        end

        it 'should not return inactive constraint by constrainable and governable' do
          param   = {:filters => {:constraint => {:id => @rg_1.id, :type => 'RouteGate'},
                                  :governor => {:id => @p_s_i_3.id, :type => 'PlanStageInstance'}}}

          xget param

          should == " "
        end

        it 'should return inactive constraint by constrainable and governable if it is specified' do
          param   = {:filters => {:constraint => {:id => @rg_1.id, :type => 'RouteGate'},
                                  :governor => {:id => @p_s_i_3.id, :type => 'PlanStageInstance'},
                                  :inactive => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@c_13.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @constraint_1 = create(:constraint)
        @constraint_2 = create(:constraint)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@constraint_1.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return constraint' do
          jget

          should have_json('number.id').with_value(@constraint_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@constraint_2.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return constraint' do
          xget

          should have_xpath('constraint/id').with_text(@constraint_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      let(:created_constraint) { Constraint.last }

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

      context 'with valid params' do
        before(:each) do
          @route_gate = create(:route_gate)
          @plan_stage_instance = create(:plan_stage_instance)
        end
        let(:param)             { {:active => true,
                                   :constrainable_id => @route_gate.id,
                                   :constrainable_type => 'RouteGate',
                                   :governable_id => @plan_stage_instance.id,
                                   :governable_type => 'PlanStageInstance'
        }
        }

        context 'JSON' do
          before :each do
            params = {json_root => param}.to_json

            jpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_json('number.id')         }
          it { should have_json('string.created_at') }
          it { should have_json('string.updated_at') }

          it 'should create constraint with active' do
            should have_json('boolean.active').with_value(true)
          end

          it 'should create constraint with constrainable_id' do
            should have_json('number.constrainable_id').with_value(@route_gate.id)
            created_constraint.constrainable_id.should == @route_gate.id
            created_constraint.constrainable.should == @route_gate
          end

          it 'should create constraint with constrainable_type' do
            should have_json('string.constrainable_type').with_value('RouteGate')
            created_constraint.constrainable_type.should == 'RouteGate'
          end

          it 'should create constraint with governable_id' do
            should have_json('number.governable_id').with_value(@plan_stage_instance.id)
            created_constraint.governable_id.should == @plan_stage_instance.id
            created_constraint.governable.should == @plan_stage_instance
          end

          it 'should create constraint with governable_type' do
            should have_json('string.governable_type').with_value('PlanStageInstance')
            created_constraint.governable_type.should == 'PlanStageInstance'
          end
        end

        context 'XML' do
          before :each do
            params = param.to_xml(:root => xml_root)

            xpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_xpath("#{xml_root}/id")         }
          it { should have_xpath("#{xml_root}/created-at") }
          it { should have_xpath("#{xml_root}/updated-at") }

          it 'should create constraint with active' do
            should have_xpath("#{xml_root}/active").with_text(true)
          end

          it 'should create constraint with constrainable-id' do
            should have_xpath("#{xml_root}/constrainable-id").with_text(@route_gate.id)
            created_constraint.constrainable_id.should == @route_gate.id
            created_constraint.constrainable.should == @route_gate
          end

          it 'should create constraint with constrainable-type' do
            should have_xpath("#{xml_root}/constrainable-type").with_text('RouteGate')
            created_constraint.constrainable_type.should == 'RouteGate'
          end

          it 'should create constraint with governable-id' do
            should have_xpath("#{xml_root}/governable-id").with_text(@plan_stage_instance.id)
            created_constraint.governable_id.should == @plan_stage_instance.id
            created_constraint.governable.should == @plan_stage_instance
          end

          it 'should create constraint with governable-type' do
            should have_xpath("#{xml_root}/governable-type").with_text('PlanStageInstance')
            created_constraint.governable_type.should == 'PlanStageInstance'
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        let(:param) { {:constrainable_id => nil} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do

      let(:updated_constraint) { Constraint.find(@constraint.id) }
      let(:url)                {"#{base_url}/#{@constraint.id}?token=#{@user.api_key}"}

      context 'with valid params' do

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
          @route_gate = create(:route_gate)
          @plan_stage_instance = create(:plan_stage_instance)
        end
        let(:param)             { {:active => false,
                                   :constrainable_id => @route_gate.id,
                                   :constrainable_type => 'RouteGate',
                                   :governable_id => @plan_stage_instance.id,
                                   :governable_type => 'PlanStageInstance'
        }
        }

        context 'JSON' do
          before :each do
            params = {json_root => param}.to_json
            @constraint = create(:constraint)

            jput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it { should have_json('number.id')         }
          it { should have_json('string.created_at') }
          it { should have_json('string.updated_at') }

          it 'should create constraint with active' do
            should have_json('boolean.active').with_value(false)
          end

          it 'should create constraint with constrainable_id' do
            should have_json('number.constrainable_id').with_value(@route_gate.id)
            updated_constraint.constrainable_id.should == @route_gate.id
            updated_constraint.constrainable.should == @route_gate
          end

          it 'should create constraint with constrainable_type' do
            should have_json('string.constrainable_type').with_value('RouteGate')
            updated_constraint.constrainable_type.should == 'RouteGate'
          end

          it 'should create constraint with governable_id' do
            should have_json('number.governable_id').with_value(@plan_stage_instance.id)
            updated_constraint.governable_id.should == @plan_stage_instance.id
            updated_constraint.governable.should == @plan_stage_instance
          end

          it 'should create constraint with governable_type' do
            should have_json('string.governable_type').with_value('PlanStageInstance')
            updated_constraint.governable_type.should == 'PlanStageInstance'
          end
        end

        context 'XML' do
          before :each do
            params = param.to_xml(:root => xml_root)
            @constraint = create(:constraint)

            xput params
          end

          subject { response.body }

          specify { response.code.should == '202' }
          it { should have_xpath("#{xml_root}/id")         }
          it { should have_xpath("#{xml_root}/created-at") }
          it { should have_xpath("#{xml_root}/updated-at") }

          it 'should create constraint with active' do
            should have_xpath("#{xml_root}/active").with_text(false)
          end

          it 'should create constraint with constrainable-id' do
            should have_xpath("#{xml_root}/constrainable-id").with_text(@route_gate.id)
            updated_constraint.constrainable_id.should == @route_gate.id
            updated_constraint.constrainable.should == @route_gate
          end

          it 'should create constraint with constrainable-type' do
            should have_xpath("#{xml_root}/constrainable-type").with_text('RouteGate')
            updated_constraint.constrainable_type.should == 'RouteGate'
          end

          it 'should create constraint with governable-id' do
            should have_xpath("#{xml_root}/governable-id").with_text(@plan_stage_instance.id)
            updated_constraint.governable_id.should == @plan_stage_instance.id
            updated_constraint.governable.should == @plan_stage_instance
          end

          it 'should create constraint with governable-type' do
            should have_xpath("#{xml_root}/governable-type").with_text('PlanStageInstance')
            updated_constraint.governable_type.should == 'PlanStageInstance'
          end
        end
      end

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) do
          @constraint = create(:constraint)
        end

        let(:param) { {:constrainable_id => nil} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @constraint = create(:constraint)
        Constraint.stub(:find).with(@constraint.id).and_return @constraint
        @constraint.should_receive(:try).with(:destroy).and_return true
      end

      let(:url) {"#{base_url}/#{@constraint.id}?token=#{@user.api_key}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @constraint.id }.to_json
          params_xml        = create_xml {|xml| xml.id @constraint.id}
          params            = eval "params_#{mimetype}"
          mimetype_headers  = eval "#{mimetype}_headers"

          delete url, params, mimetype_headers

          response.status.should == 202
        end
      end
    end
  end

  context 'with invalid api key' do
    let(:token) { 'invalid_api_key' }

    methods_urls_for_403 = {
        get:      ["#{base_url}", "#{base_url}/1"],
        post:     ["#{base_url}"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    test_batch_of_requests methods_urls_for_403, :response_code => 403
  end

  context 'with no existing constraints' do
    before :each do
      # make sure there's none of constraints
      Constraint.delete_all
    end

    let(:token) { @token }

    methods_urls_for_404 = {
        get:      ["#{base_url}", "#{base_url}/1"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_404, :response_code => 404, mimetypes: mimetypes
  end
end
