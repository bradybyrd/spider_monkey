require 'spec_helper'

base_url =  '/v1/environments'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :environment }
  let(:xml_root) { 'environment' }

  before :all do
    @user         = create(:user)
    @token        = @user.api_key
  end

  shared_examples 'filters out included data with include_except' do
    context 'include_except' do
      it 'should return included attributes e.g. requests, installed_components' do
        jget

        expect(subject).to have_json('object > array.requests')
        expect(subject).to have_json('object > array.installed_components')
      end

      it 'should not return included attributes e.g. requests when we filter them out' do
        param = {filters: {include_except: 'requests,installed_components'}}

        jget param

        expect(subject).to_not have_json('object > array.requests')
        expect(subject).to_not have_json('object > array.include_except')
      end
    end
  end

  context 'with existing environments and valid api key' do
    before(:each)  do
      @server_group_1 = create(:server_group)
      @server_group_2 = create(:server_group)
      @server_1       = create(:server)
      @server_2       = create(:server)
      @env_type       = create(:environment_type, description: 'This is environment type for testing')
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      let(:xml_root) {'environments/environment'}

      before(:each) do
        @env_type_other = create(:environment_type, description: 'This is other environment type for testing')

        @env_1 = create(:environment)
        @env_2 = create(:environment, name: 'fire_in_the_hole', environment_type: @env_type)
        @env_3 = create(:environment, name: 'mad name', environment_type: @env_type_other, active: false)

        @active_environment_ids = [@env_2.id, @env_1.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all environments except inactive(by default)' do
          jget

          expect(subject).to have_json(':root > object > number.id').with_values(@active_environment_ids)
        end

        it 'should return all environments except inactive' do
          param   = {filters: {active: true}}

          jget param

          expect(subject).to have_json(':root > object > number.id').with_values(@active_environment_ids)
        end

        it 'should return all environments inactive' do
          param   = {filters: {inactive: true}}

          jget param

          expect(subject).to have_json(':root > object > number.id').with_values([@env_3.id])
        end

        it 'should return all environments' do
          param   = {filters: {inactive: true, active: true}}

          jget param

          expect(subject).to have_json(':root > object > number.id').with_values([@env_3.id] + @active_environment_ids)
        end

        it 'should return all inactive environments' do
          param   = {filters: {inactive: true, active: false}}

          jget param

          expect(subject).to have_json(':root > object > number.id').with_value(@env_3.id)
        end

        it 'should return environment by `name` and `environment type`' do
          param   = {filters: {name: 'fire_in_the_hole', environment_type: @env_type.id}}

          jget param

          expect(subject).to have_json(':root > object > number.id').with_value(@env_2.id)
        end

        it 'should not return inactive environment by `name` and `environment type`' do
          param   = {filters: {name: 'mad name', environment_type: @env_type_other.id}}

          jget param

          expect(subject).to eq ' '
        end

        it 'should return inactive environment by `name` and `environment type` if it is specified' do
          param   = {filters: {name: 'mad name', environment_type: @env_type_other.id, inactive: true}}

          jget param

          expect(subject).to have_json(':root > object > number.id').with_value(@env_3.id)
        end

        context 'deployment windows' do
          it 'should return environment by deployment_window_event_id' do
            env_e = create(:environment)
            dwe = create(:deployment_window_event, environment_id: env_e.id)
            param = {filters: { deployment_window_event_id: dwe.id }}

            jget param

            expect(subject).to have_json(':root > object > number.id').with_value(env_e.id)
          end

          it 'should return environment by deployment_window_series_id' do
            dws = create(:deployment_window_event, :with_allow_series).series
            env_s = dws.environments.first
            param = {filters: { deployment_window_series_id: dws.id }}

            jget param

            expect(subject).to have_json(':root > object > number.id').with_value(env_s.id)
          end
        end
      end

      context 'XML' do
        subject { response.body }

        it 'should return all environments except inactive(by default)' do
          xget

          expect(subject).to have_xpath("#{xml_root}/id").with_texts(@active_environment_ids)
        end

        it 'should return all environments except inactive' do
          param   = {filters: {active: true}}

          xget param

          expect(subject).to have_xpath("#{xml_root}/id").with_texts(@active_environment_ids)
        end

        it 'should return all environments inactive' do
          param   = {filters: {inactive: true}}

          xget param

          expect(subject).to have_xpath("#{xml_root}/id").with_texts([@env_3.id])
        end

        it 'should return all environments' do
          param   = {filters: {inactive: true, active: true}}

          xget param

          expect(subject).to have_xpath("#{xml_root}/id").with_texts([@env_3.id] + @active_environment_ids)
        end

        it 'should return all inactive environments' do
          param   = {filters: {inactive: true, active: false}}

          xget param

          expect(subject).to have_xpath("#{xml_root}/id").with_text(@env_3.id)
        end

        it 'should return environment by `name` and `environment type`' do
          param   = {filters: {name: 'fire_in_the_hole', environment_type: @env_type.id}}

          xget param

          expect(subject).to have_xpath("#{xml_root}/id").with_text(@env_2.id)
        end

        it 'should not return inactive environment by `name` and `environment type` if that was not specified' do
          param   = {filters: {name: 'mad name', environment_type: @env_type_other.id}}

          xget param

          expect(subject).to eq ' '
        end

        it 'should return inactive environment by `name` and `environment type` if it is specified' do
          param   = {filters: {name: 'mad name', environment_type: @env_type_other.id, inactive: true}}

          xget param

          expect(subject).to have_xpath("#{xml_root}/id").with_text(@env_3.id)
        end

        context 'deployment windows' do
          it 'should return environment by deployment_window_event_id' do
            env_e = create(:environment)
            dwe = create(:deployment_window_event, environment_id: env_e.id)
            param = {filters: { deployment_window_event_id: dwe.id }}

            xget param

            expect(subject).to have_xpath("#{xml_root}/id").with_text(env_e.id)
          end

          it 'should return environment by deployment_window_series_id' do
            dws = create(:deployment_window_event, :with_allow_series).series
            env_s = dws.environments.first
            param = {filters: { deployment_window_series_id: dws.id }}

            xget param

            expect(subject).to have_xpath("#{xml_root}/id").with_text(env_s.id)
          end

        end
      end

      it_behaves_like 'entity with include_exclude support' do
        let(:excludes) { %w(requests apps) }
      end
    end

    describe "GET #{base_url}/[id]" do
      let(:url) {"#{base_url}/#{@environment_1.id}?token=#{@user.api_key}"}
      before(:each) do
        @environment_1 = create(:environment)
        @environment_2 = create(:environment)

        @route_1 = create(:route)
        @route_2 = create(:route, route_type: 'mixed')
        @route_3 = create(:route, route_type: 'strict')

        @rg_11 = create(:route_gate, environment: @environment_1, route: @route_1, description: 'RouteGate from Env #1 to Route #1')
        @rg_12 = create(:route_gate, environment: @environment_1, route: @route_2, description: 'RouteGate from Env #1 to Route #2')
        @rg_22 = create(:route_gate, environment: @environment_2, route: @route_2, description: 'RouteGate from Env #2 to Route #2')
        @rg_23 = create(:route_gate, environment: @environment_2, route: @route_3, description: 'RouteGate from Env #2 to Route #3')
      end

      context 'JSON' do
        before(:each) { jget }

        subject { response.body }

        it { expect(subject).to have_json('number.id').with_value(@environment_1.id) }

        it { expect(subject).to have_json('array.route_gates > object > number.id').with_values([@rg_11.id, @rg_12.id]) }
        it { expect(subject).to have_json('array.route_gates > object > string.description').with_values([@rg_11.description, @rg_12.description]) }
        it { expect(subject).to have_json('array.route_gates > object > object > number.id').with_values([@route_1.id, @route_2.id]) }
        it { expect(subject).to have_json('array.route_gates > object > object > string.name').with_values([@route_1.name, @route_2.name]) }
        it { expect(subject).to have_json('array.route_gates > object > object > string.route_type').with_values([@route_1.route_type, @route_2.route_type]) }
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@environment_2.id}?token=#{@user.api_key}"}

        before(:each) { xget }

        subject { response.body }

        it { expect(subject).to have_xpath("#{xml_root}/id").with_text(@environment_2.id) }

        it { expect(subject).to have_xpath("#{xml_root}/route-gates/route-gate/id").with_texts([@rg_22.id, @rg_23.id]) }
        it { expect(subject).to have_xpath("#{xml_root}/route-gates/route-gate/description").with_texts([@rg_22.description, @rg_23.description]) }
        it { expect(subject).to have_xpath("#{xml_root}/route-gates/route-gate/route/id").with_texts([@route_2.id, @route_3.id]) }
        it { expect(subject).to have_xpath("#{xml_root}/route-gates/route-gate/route/name").with_texts([@route_2.name, @route_3.name]) }
        it { expect(subject).to have_xpath("#{xml_root}/route-gates/route-gate/route/route-type").with_texts([@route_2.route_type, @route_3.route_type]) }
      end

      it_behaves_like 'entity with include_exclude support' do
        let(:excludes) { %w(requests apps) }
      end
    end

    describe "POST #{base_url}" do
      let(:created_environment) { Environment.last }

      context 'with valid params' do
        let(:param)             { {name: 'DiesIrae',
                                   active: false,
                                   environment_type_id: @env_type.id,
                                   default_server_group_id: @server_group_1.id,
                                   default: true,
                                   server_group_ids: [@server_group_1.id, @server_group_2.id],
                                   server_ids: [@server_1.id, @server_2.id]
        }
        }

        context 'JSON' do
          before :each do
            params    = {json_root => param}.to_json

            jpost params
          end

          subject { response.body }

          specify { expect(response.code).to eq '201' }

          it { expect(subject).to have_json('string.created_at')          }
          it { expect(subject).to have_json('string.updated_at')          }
          it { expect(subject).to have_json('array.apps')                 }
          it { expect(subject).to have_json('array.assigned_apps')        }
          it { expect(subject).to have_json('array.requests')             }
          it { expect(subject).to have_json('array.installed_components') }

          it 'should create environment with name' do
            expect(subject).to have_json('string.name').with_value('DiesIrae')
          end

          it 'should create inactive environment' do
            expect(subject).to have_json('boolean.active').with_value(false)
          end

          it 'should create environment with `environment type`' do
            expect(subject).to have_json('object.environment_type number.id').with_value(@env_type.id)
            expect(subject).to have_json('object.environment_type string.name').with_value(@env_type.name)
            expect(subject).to have_json('object.environment_type string.description').with_value(@env_type.description)
            expect(created_environment.environment_type).to eq @env_type
          end

          it 'should create environment with `default_server_group`' do
            expect(subject).to have_json('number.default_server_group_id').with_value(@server_group_1.id)
            expect(created_environment.default_server_group).to eq @server_group_1
          end

          it 'should create non-default environment' do
            expect(subject).to have_json('boolean.default').with_value(true)
          end

          it 'should create environment with given `server_groups`' do
            expect(subject).to have_json('array.server_groups number.id').with_values([@server_group_1.id, @server_group_2.id])
            expect(created_environment.server_groups).to match_array [@server_group_1, @server_group_2]
          end

          it 'should create environment with given `servers`' do
            expect(subject).to have_json('array.servers number.id').with_values([@server_1.id, @server_2.id])
            expect(created_environment.servers).to match_array [@server_1, @server_2]
          end
        end

        context 'XML' do
          before :each do
            params    = param.to_xml(root: xml_root)

            xpost params
          end

          subject { response.body }

          specify { expect(response.code).to eq '201' }

          it { expect(subject).to have_xpath("#{xml_root}/created-at")           }
          it { expect(subject).to have_xpath("#{xml_root}/updated-at")           }
          it { expect(subject).to have_xpath("#{xml_root}/apps")                 }
          it { expect(subject).to have_xpath("#{xml_root}/assigned-apps")        }
          it { expect(subject).to have_xpath("#{xml_root}/requests")             }
          it { expect(subject).to have_xpath("#{xml_root}/installed-components") }

          it 'should create environment with name' do
            expect(subject).to have_xpath("#{xml_root}/name").with_text('DiesIrae')
          end

          it 'should create inactive environment' do
            expect(subject).to have_xpath("#{xml_root}/active").with_text(false)
          end

          it 'should create environment with `environment type`' do
            expect(subject).to have_xpath("#{xml_root}/environment-type/id").with_text(@env_type.id)
            expect(subject).to have_xpath("#{xml_root}/environment-type/name").with_text(@env_type.name)
            expect(subject).to have_xpath("#{xml_root}/environment-type/description").with_text(@env_type.description)
            expect(created_environment.environment_type).to eq @env_type
          end

          it 'should create environment with `default_server_group`' do
            expect(subject).to have_xpath("#{xml_root}/default-server-group-id").with_text(@server_group_1.id)
            expect(created_environment.default_server_group).to eq @server_group_1
          end

          it 'should create non-default environment' do
            expect(subject).to have_xpath("#{xml_root}/default").with_text(true)
          end

          it 'should create environment with given `server_groups`' do
            expect(subject).to have_xpath("#{xml_root}/server-groups/server-group/id").with_texts([@server_group_1.id, @server_group_2.id])
            expect(created_environment.server_groups).to match_array [@server_group_1, @server_group_2]
          end

          it 'should create environment with given `servers`' do
            expect(subject).to have_xpath("#{xml_root}/servers/server/id").with_texts([@server_1.id, @server_2.id])
            expect(created_environment.servers).to match_array [@server_1, @server_2]
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        before(:each)  { create(:environment, name: 'already exists') }

        let(:param) { {name: 'already exists'} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do

      let(:updated_environment) { Environment.find(@environment.id) }
      let(:url)               {"#{base_url}/#{@environment.id}?token=#{@user.api_key}"}

      context 'with valid params' do
        let(:param)             { {name: 'AgnusDei',
                                   active: true,
                                   environment_type_id: @env_type.id,
                                   default_server_group_id: nil,
                                   default: false,
                                   server_group_ids: [@server_group_2.id],
                                   server_ids: [@server_1.id]
        }
        }

        context 'JSON' do
          before :each do
            params       = {json_root => param}.to_json
            @environment = create(:environment, default: true, active: false)

            jput params
          end

          subject { response.body }

          specify { expect(response.code).to eq '202' }

          it 'should update environment with name' do
            expect(subject).to have_json('string.name').with_value('AgnusDei')
          end

          it 'should update inactive environment' do
            expect(subject).to have_json('boolean.active').with_value(true)
          end

          it 'should update environment with `environment type`' do
            expect(subject).to have_json('object.environment_type number.id').with_value(@env_type.id)
            expect(subject).to have_json('object.environment_type string.name').with_value(@env_type.name)
            expect(subject).to have_json('object.environment_type string.description').with_value(@env_type.description)
            expect(updated_environment.environment_type).to eq @env_type
          end

          it 'should update environment with `default_server_group`' do
            expect(subject).to have_json('*.default_server_group_id').with_value(nil)
            expect(updated_environment.default_server_group).to be_nil
          end

          it 'should update non-default environment' do
            expect(subject).to have_json('boolean.default').with_value(false)
          end

          it 'should update environment with given `server_groups`' do
            expect(subject).to have_json('array.server_groups number.id').with_value(@server_group_2.id)
            expect(updated_environment.server_groups).to match_array [@server_group_2]
          end

          it 'should update environment with given `server`' do
            expect(subject).to have_json('array.servers number.id').with_value(@server_1.id)
            expect(updated_environment.servers).to match_array [@server_1]
          end
          it_behaves_like 'filters out included data with include_except'
        end

        context 'XML' do
          before :each do
            params       = param.to_xml(root: xml_root)
            @environment = create(:environment, default: true, active: false)

            xput params
          end

          subject { response.body }

          specify { expect(response.code).to eq '202' }

          it 'should update environment with name' do
            expect(subject).to have_xpath("#{xml_root}/name").with_text('AgnusDei')
          end

          it 'should update inactive environment' do
            expect(subject).to have_xpath("#{xml_root}/active").with_text(true)
          end

          it 'should update environment with `environment type`' do
            expect(subject).to have_xpath("#{xml_root}/environment-type/id").with_text(@env_type.id)
            expect(subject).to have_xpath("#{xml_root}/environment-type/name").with_text(@env_type.name)
            expect(subject).to have_xpath("#{xml_root}/environment-type/description").with_text(@env_type.description)
            expect(updated_environment.environment_type).to eq @env_type
          end

          it 'should update environment with `default_server_group`' do
            expect(subject).to have_xpath("#{xml_root}/default-server-group-id").with_text(nil)
            expect(updated_environment.default_server_group).to be_nil
          end

          it 'should update non-default environment' do
            expect(subject).to have_xpath("#{xml_root}/default").with_text(false)
          end

          it 'should update environment with given `server_groups`' do
            expect(subject).to have_xpath("#{xml_root}/server-groups/server-group/id").with_text(@server_group_2.id)
            expect(updated_environment.server_groups).to match_array [@server_group_2]
          end

          it 'should update environment with given `server`' do
            expect(subject).to have_xpath("#{xml_root}/servers/server/id").with_text(@server_1.id)
            expect(updated_environment.servers).to match_array [@server_1]
          end
        end
      end

      it_behaves_like 'change `active` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each)  { @environment = create(:environment) }

        let(:param) { {name: ''} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do

      before(:each) { @environment = create(:environment) }

      let(:url) {"#{base_url}/#{@environment.id}?token=#{@user.api_key}"}

      subject { response.body }

      mimetypes = %w(json xml)
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @environment.id }.to_json
          params_xml        = create_xml {|xml| xml.id @environment.id}
          param            = eval "params_#{mimetype}"
          mimetype_headers  = eval "#{mimetype}_headers"

          delete url, param, mimetype_headers
          @environment.reload

          expect(response.status).to eq 202
          expect(@environment.active).to be_falsey
        end
      end
      it_behaves_like 'filters out included data with include_except'
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

    test_batch_of_requests methods_urls_for_403, response_code: 403
  end

  context 'with no existing environments' do

    let(:token)    { @token }

    methods_urls_for_404 = {
        get:      ["#{base_url}", "#{base_url}/1"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    mimetypes = %w(json xml)

    test_batch_of_requests methods_urls_for_404, response_code: 404, mimetypes: mimetypes
  end

end
