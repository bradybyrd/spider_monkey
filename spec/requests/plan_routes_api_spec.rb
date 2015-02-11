require 'spec_helper'

base_url =  '/v1/plan_routes'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) {:plan_route}
  let(:xml_root) {'plan-route'}

  before :all do
    @user         = create(:user)
    @token        = @user.api_key
  end

  context 'with existing plan routes and valid api key' do

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @plan_1 = create(:plan)
        @plan_2 = create(:plan)

        @route_1 = create(:route)
        @route_2 = create(:route)

        @plan_route_11 = create(:plan_route, :plan => @plan_1, :route => @route_1)
        @plan_route_12 = create(:plan_route, :plan => @plan_1, :route => @route_2)
        @plan_route_21 = create(:plan_route, :plan => @plan_2, :route => @route_1)
        @plan_route_22 = create(:plan_route, :plan => @plan_2, :route => @route_2)
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all plan routes(by default)' do
          jget

          should have_json(':root > object > number.id').with_values([@plan_route_11.id, @plan_route_12.id, @plan_route_21.id, @plan_route_22.id])
        end

        it 'should return plan routes by `plan id`' do
          param   = {:filters => {:plan_id => @plan_1.id}}

          jget param

          should have_json(':root > object > number.id').with_values([@plan_route_11.id, @plan_route_12.id])
        end

        it 'should return plan routes by `route id`' do
          param   = {:filters => {:route_id => @route_1.id}}

          jget param

          should have_json(':root > object > number.id').with_values([@plan_route_11.id, @plan_route_21.id])
        end

        it 'should return plan routes by `plan id` and `route id`' do
          param   = {:filters => {:plan_id => @plan_2.id, :route_id => @route_2.id}}

          jget param

          should have_json(':root > object > number.id').with_value(@plan_route_22.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'plan-routes/plan-route'}
        subject { response.body }


        it 'should return all plan routes(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts([@plan_route_11.id, @plan_route_12.id, @plan_route_21.id, @plan_route_22.id])
        end

        it 'should return plan routes by `plan id`' do
          param   = {:filters => {:plan_id => @plan_1.id}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@plan_route_11.id, @plan_route_12.id])
        end

        it 'should return plan routes by `route id`' do
          param   = {:filters => {:route_id => @route_1.id}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@plan_route_11.id, @plan_route_21.id])
        end

        it 'should return plan routes by `plan id` and `route id`' do
          param   = {:filters => {:plan_id => @plan_2.id, :route_id => @route_2.id}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@plan_route_22.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @pr_1 = create(:plan_route)
        @pr_2 = create(:plan_route)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@pr_1.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return route' do
          jget

          should have_json('number.id').with_value(@pr_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@pr_2.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return route' do
          xget

          should have_xpath("#{xml_root}/id").with_text(@pr_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      before(:each) do
        @plan = create(:plan)
        @route = create(:route)
      end

      let(:created_plan_route) { PlanRoute.last }

      context 'with valid params' do
        let(:param)             { {:plan_id => @plan.id,
                                   :route_id => @route.id
        }
        }

        context 'JSON' do
          before :each do
            params    = {json_root => param}.to_json

            jpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_json('string.created_at')          }
          it { should have_json('string.updated_at')          }
          it { should have_json('number.id')                  }

          it 'should create plan route with given `plan`' do
            should have_json('object.plan number.id').with_value(@plan.id)
            created_plan_route.plan.should == @plan
          end

          it 'should create plan route with given `route`' do
            should have_json('object.route number.id').with_value(@route.id)
            created_plan_route.route.should == @route
          end
        end

        context 'XML' do
          before :each do
            params    = param.to_xml(:root => xml_root)

            xpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_xpath("#{xml_root}/created-at")           }
          it { should have_xpath("#{xml_root}/updated-at")           }
          it { should have_xpath("#{xml_root}/id")                   }

          it 'should create plan route with given `plan`' do
            should have_xpath("#{xml_root}/plan/id").with_text(@plan.id)
            created_plan_route.plan.should == @plan
          end

          it 'should create plan route with given `route`' do
            should have_xpath("#{xml_root}/route/id").with_text(@route.id)
            created_plan_route.route.should == @route
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        let(:param) { {:plan_id => nil} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      let(:token) { @token }

      methods_urls_for_405 = {
          put:      ["#{base_url}/1"],
      }

      mimetypes = ['json', 'xml']

      test_batch_of_requests methods_urls_for_405, :response_code => 405, :mimetypes => mimetypes
    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @plan_route = create(:plan_route)
        PlanRoute.stub(:find).with(@plan_route.id).and_return @plan_route
        @plan_route.should_receive(:try).with(:destroy).and_return true
      end

      let(:url) {"#{base_url}/#{@plan_route.id}?token=#{@user.api_key}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @plan_route.id }.to_json
          params_xml        = create_xml {|xml| xml.id @plan_route.id}
          params            = eval "params_#{mimetype}"
          mimetype_headers  = eval "#{mimetype}_headers"

          delete url, params, mimetype_headers

          response.status.should == 202
        end
      end
    end
  end

  context 'with invalid api key' do
    let(:token)     { 'invalid_api_key' }

    methods_urls_for_403 = {
        get:      ["#{base_url}", "#{base_url}/1"],
        post:     ["#{base_url}"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    test_batch_of_requests methods_urls_for_403, :response_code => 403
  end

  context 'with no existing routes' do
    let(:token)    { @token }

    methods_urls_for_404 = {
        get:      ["#{base_url}", "#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_404, :response_code => 404, mimetypes: mimetypes
  end
end