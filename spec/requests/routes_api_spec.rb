require 'spec_helper'

base_url =  '/v1/routes'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) {:route}
  let(:xml_root) {'route'}

  before :all do
    @user         = create(:user)
    @token        = @user.api_key
  end

  context 'with existing routes and valid api key' do
    before(:each)  do
      @app = create(:app)
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @route_1 = create(:route, :name => ' Route #1', :app => @app)
        @route_2 = create(:route, :name => ' Route #2')
        @route_2.archive
        @route_2.reload
        @archived_name = @route_2.name
        @route_3 = create(:route, :name => ' Route #3', :route_type => 'mixed')

        @active_ids = [@route_1.id, @route_3.id]
        [@route_1, @route_2, @route_3].each do |route|
          @active_ids << Route.default_route_for_app_id(route.app_id).id
        end
        @route_ids_for_app_1 = [@route_1.id, @app.default_route.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all routes except archived(by default)' do
          jget

          should have_json(':root > object > number.id').with_values(@active_ids)
        end

        it 'should return routes by app id' do
          param   = {:filters => {:app_id => @app.id}}

          jget param

          should have_json(':root > object > number.id').with_values(@route_ids_for_app_1)
        end

        it 'should return routes by route type' do
          param   = {:filters => {:route_type => 'mixed'}}

          jget param

          should have_json(':root > object > number.id').with_value(@route_3.id)
        end

        it 'should not return archived route by name' do
          param   = {:filters => {:name => @archived_name}}

          jget param

          should == ' '
        end

        it 'should return archived route by name if it is specified' do
          param   = {:filters => {:name => @archived_name, :archived => true}}

          jget param

          should have_json('number.id').with_value(@route_2.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'routes/route'}
        subject { response.body }

        it 'should return all routes except archived(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@active_ids)
        end

        it 'should return routes by app id' do
          param   = {:filters => {:app_id => @app.id}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@route_ids_for_app_1)
        end

        it 'should return routes by route type' do
          param   = {:filters => {:route_type => 'mixed'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@route_3.id)
        end

        it 'should not return archived route by name' do
          param   = {:filters => {:name => @archived_name}}

          xget param

          should == ' '
        end

        it 'should return archived route by name if it is specified' do
          param   = {:filters => {:name => @archived_name, :archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@route_2.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @rg_1 = create(:route)
        @rg_2 = create(:route)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@rg_1.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return route' do
          jget

          should have_json('number.id').with_value(@rg_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@rg_2.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return route' do
          xget

          should have_xpath('route/id').with_text(@rg_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      before(:each) do
        @route_gate_1 = create(:route_gate)
        @route_gate_2 = create(:route_gate)
        @plan_route_1 = create(:plan_route, route: @route_gate_1.route)
        @plan_route_2 = create(:plan_route, route: @route_gate_2.route)
      end

      let(:created_route) { Route.last }

      context 'with valid params' do
        let(:param)             { {:name => 'Route #135',
                                   :description => 'Description for Route',
                                   :route_type => 'mixed',
                                   :app_id => @app.id
        }
        }

        context 'JSON' do
          before :each do
            params    = {:route => param}.to_json

            jpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_json('*.archive_number')           }
          it { should have_json('*.archived_at')              }
          it { should have_json('string.created_at')          }
          it { should have_json('string.updated_at')          }
          it { should have_json('number.id')                  }

          it 'should create route with name' do
            should have_json('string.name').with_value('Route #135')
          end

          it 'should create route with description' do
            should have_json('string.description').with_value('Description for Route')
          end

          it 'should create route with route type' do
            should have_json('string.route_type').with_value('mixed')
          end

          it 'should create route with app' do
            should have_json('object.app number.id').with_value(@app.id)
            created_route.app.should == @app
          end

        end

        context 'XML' do
          before :each do
            params    = param.to_xml(:root => xml_root)

            xpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_xpath("#{xml_root}/archive-number")       }
          it { should have_xpath("#{xml_root}/archived-at")          }
          it { should have_xpath("#{xml_root}/created-at")           }
          it { should have_xpath("#{xml_root}/updated-at")           }
          it { should have_xpath("#{xml_root}/id")                   }

          it 'should create route with name' do
            should have_xpath("#{xml_root}/name").with_text('Route #135')
          end

          it 'should create route with description' do
            should have_xpath("#{xml_root}/description").with_text('Description for Route')
          end

          it 'should create route with route type' do
            should have_xpath("#{xml_root}/route-type").with_text('mixed')
          end

          it 'should create route with app' do
            should have_xpath("#{xml_root}/app/id").with_text(@app.id)
            created_route.app.should == @app
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        before(:each) { @route = create(:route) }

        let(:param)             { {:name => @route.name , :app_id => @route.app_id} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      before(:each) do
        @route_gate_1 = create(:route_gate)
        @route_gate_2 = create(:route_gate)
        @plan_route_1 = create(:plan_route)
        @plan_route_2 = create(:plan_route)
      end

      let(:updated_route) { Route.find(@route.id) }
      let(:url)           {"#{base_url}/#{@route.id}?token=#{@user.api_key}"}

      context 'with valid params' do
        let(:param)             { {:name => 'Route #135',
                                   :description => 'Description for Route',
                                   :route_type => 'mixed',
                                   :app_id => @app.id,
                                   :route_gate_ids => [@route_gate_1.id, @route_gate_2.id],
                                   :plan_route_ids => [@plan_route_1.id, @plan_route_2.id]
        }
        }

        context 'JSON' do
          before :each do
            params       = {:route => param}.to_json
            @route = create(:route)

            jput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it { should have_json('*.archive_number')           }
          it { should have_json('*.archived_at')              }
          it { should have_json('string.created_at')          }
          it { should have_json('string.updated_at')          }
          it { should have_json('number.id')                  }

          it 'should update route with name' do
            should have_json('string.name').with_value('Route #135')
          end

          it 'should update route with description' do
            should have_json('string.description').with_value('Description for Route')
          end

          it 'should update route with route type' do
            should have_json('string.route_type').with_value('mixed')
          end

          it 'should update route with app' do
            should have_json('object.app number.id').with_value(@app.id)
            updated_route.app.should == @app
          end

          it 'should update route with given `route gates`' do
            should have_json('array.route_gates > object > number.id').with_values([@route_gate_1.id, @route_gate_2.id])
            updated_route.route_gates.should match_array [@route_gate_1, @route_gate_2]
          end

          it 'should update route with given `plan routes`' do
            should have_json('array.plan_routes > object > number.id').with_values([@plan_route_1.id, @plan_route_2.id])
            updated_route.plan_routes.should match_array [@plan_route_1, @plan_route_2]
          end
        end

        context 'XML' do
          before :each do
            params       = param.to_xml(:root => xml_root)
            @route = create(:route)

            xput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it 'should update route with name' do
            should have_xpath("#{xml_root}/name").with_text('Route #135')
          end

          it 'should update route with description' do
            should have_xpath("#{xml_root}/description").with_text('Description for Route')
          end

          it 'should update route with route type' do
            should have_xpath("#{xml_root}/route-type").with_text('mixed')
          end

          it 'should update route with app' do
            should have_xpath("#{xml_root}/app/id").with_text(@app.id)
            updated_route.app.should == @app
          end

          it 'should update route with given `route gates`' do
            should have_xpath("#{xml_root}/route-gates/route-gate/id").with_texts([@route_gate_1.id, @route_gate_2.id])
            updated_route.route_gates.should match_array [@route_gate_1, @route_gate_2]
          end

          it 'should update route with given `plan routes`' do
            should have_xpath("#{xml_root}/plan-routes/plan-route/id").with_texts([@plan_route_1.id, @plan_route_2.id])
            updated_route.plan_routes.should match_array [@plan_route_1, @plan_route_2]
          end
        end
      end

      it_behaves_like 'with `toggle_archive` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) do
          create(:route)
          @route = create(:route)
        end

        let(:param)             { {:name => Route.first.name, :app_id => Route.first.app_id} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @route = create(:route)
        Route.stub(:find).with(@route.id).and_return @route
        @route.should_receive(:try).with(:destroy).and_return true
      end

      let(:url) {"#{base_url}/#{@route.id}?token=#{@user.api_key}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @route.id }.to_json
          params_xml        = create_xml {|xml| xml.id @route.id}
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
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_404, :response_code => 404, mimetypes: mimetypes
  end
end