require 'spec_helper'

base_url = '/v1/servers'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :server }
  let(:xml_root) { 'server' }

  before :all do
    @user         = create(:user)
    @user.reload
    @token        = @user.api_key
  end

  context 'with existing servers and valid api key' do

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @nt_1 = create(:server)
        @nt_2 = create(:server, :name => 'Unum castigabis, centum emendabis')
        @nt_3 = create(:server, :name => 'mad', :active => false)

        @active_nt_ids = [@nt_2.id, @nt_1.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all servers except inactive(by default)' do
          jget

          should have_json('number.id').with_values(@active_nt_ids)
        end

        it 'should return all servers except inactive' do
          param   = {:filters => {:active => true}}

          jget param

          should have_json('number.id').with_values(@active_nt_ids)
        end

        it 'should return all servers inactive' do
          param   = {:filters => {:inactive => true}}

          jget param

          should have_json('number.id').with_values([@nt_3.id])
        end

        it 'should return all servers' do
          param   = {:filters => {:inactive => true, :active => true}}

          jget param

          should have_json('number.id').with_values([@nt_3.id] + @active_nt_ids)
        end

        it 'should return all inactive servers' do
          param   = {:filters => {:inactive => true, :active => false}}

          jget param

          should have_json('number.id').with_value(@nt_3.id)
        end

        it 'should return server by name' do
          param   = {:filters => {:name => 'Unum castigabis, centum emendabis'}}

          jget param

          should have_json('number.id').with_value(@nt_2.id)
        end

        it 'should not return inactive server by name' do
          param   = {:filters => {:name => 'mad'}}

          jget param

          should == " "
        end

        it 'should return inactive server by name if it is specified' do
          param   = {:filters => {:name => 'mad', :inactive => true}}

          jget param

          should have_json('number.id').with_value(@nt_3.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'servers/server'}

        subject { response.body }

        it 'should return all servers except inactive(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@active_nt_ids)
        end

        it 'should return all servers except inactive' do
          param   = {:filters => {:active => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@active_nt_ids)
        end

        it 'should return all servers inactive' do
          param   = {:filters => {:inactive => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@nt_3.id])
        end

        it 'should return all servers' do
          param   = {:filters => {:inactive => true, :active => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@nt_3.id] + @active_nt_ids)
        end

        it 'should return all inactive servers' do
          param   = {:filters => {:inactive => true, :active => false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@nt_3.id)
        end

        it 'should return server by name' do
          param   = {:filters => {:name => 'Unum castigabis, centum emendabis'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@nt_2.id)
        end

        it 'should not return inactive server by name if that was not specified' do
          param   = {:filters => {:name => 'mad'}}

          xget param

          should == " "
        end

        it 'should return inactive server by name if it is specified' do
          param   = {:filters => {:name => 'mad', :inactive => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@nt_3.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @nt_1 = create(:server)
        @nt_2 = create(:server)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@nt_1.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return server' do
          jget

          should have_json('number.id').with_value(@nt_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@nt_2.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return server' do
          xget

          should have_xpath('server/id').with_text(@nt_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      let(:environment) { create(:environment) }
      let(:property) { create(:property) }
      let(:server_group) { create(:server_group) }
      let(:url) { "#{base_url}/?token=#{@user.api_key}" }

      it_behaves_like "successful request", type: :json, method: :post, status: 201 do
        let(:name) { "Server_json" }
        let(:dns) { "host_json.streamstep.com" }
        let(:ip_address) { "127.0.0.1" }
        let(:os_platform) { "centos5" }
        let(:params) { { json_root => { name: name,
                                        dns: dns,
                                        ip_address: ip_address,
                                        os_platform: os_platform,
                                        environment_ids: [environment.id],
                                        property_ids: [property.id],
                                        server_group_ids: [server_group.id] } }.to_json }
        let(:added_server) { Server.where(name: name).first }

        subject { response.body }
        it { should have_json('number.id').with_value(added_server.id) }
        it { should have_json('string.name').with_value(added_server.name) }
        it { should have_json('string.dns').with_value(added_server.dns) }
        it { should have_json('string.ip_address').with_value(added_server.ip_address) }
        it { should have_json('string.os_platform').with_value(added_server.os_platform) }
        it { should have_json('.environments .id').with_value(environment.id) }
        it { should have_json('.properties .id').with_value(property.id) }
        it { should have_json('.server_groups .id').with_value(server_group.id) }
        it { should have_json('boolean.active').with_value(true) }
      end

      it_behaves_like "successful request", type: :xml, method: :post, status: 201 do
        let(:name) { "Server_xml" }
        let(:dns) { "host_xml.streamstep.com" }
        let(:ip_address) { "192.168.0.1" }
        let(:os_platform) { "centos5" }
        let(:params) { { name: name,
                         dns: dns,
                         ip_address: ip_address,
                         os_platform: os_platform,
                         environment_ids: [environment.id],
                         property_ids: [property.id],
                         server_group_ids: [server_group.id] }.to_xml(root: xml_root) }
        let(:added_server) { Server.where(name: name).first }

        subject { response.body }
        it { should have_xpath('/server/id').with_text(added_server.id) }
        it { should have_xpath('/server/dns').with_text(added_server.dns) }
        it { should have_xpath('/server/name').with_text(added_server.name) }
        it { should have_xpath('/server/ip-address').with_text(added_server.ip_address) }
        it { should have_xpath('/server/os-platform').with_text(added_server.os_platform) }
        it { should have_xpath('/server/environments/environment/id').with_text(environment.id) }
        it { should have_xpath('/server/properties/property/id').with_text(property.id) }
        it { should have_xpath('/server/server-groups/server-group/id').with_text(server_group.id) }
        it { should have_xpath('/server/active').with_text('true') }
      end

      it_behaves_like 'creating request with params that fails validation' do
        before(:each) { @server = create(:server) }

        let(:param) { {:name => Server.last.name} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      before(:each) { @server = create(:server) }
      let(:new_environment) { create(:environment) }
      let(:new_property) { create(:property) }
      let(:new_server_group) { create(:server_group) }
      let(:url) { "#{base_url}/#{@server.id}/?token=#{@user.api_key}" }

      it_behaves_like "successful request", type: :json, method: :put, status: 202 do
        let(:new_name) { "Server_json_new" }
        let(:new_dns) { "host_json_new.streamstep.com" }
        let(:new_ip_address) { "192.168.0.2" }
        let(:new_os_platform) { "centos5" }
        let(:params) { { json_root => { name: new_name,
                                        dns: new_dns,
                                        ip_address: new_ip_address,
                                        os_platform: new_os_platform,
                                        environment_ids: [new_environment.id],
                                        property_ids: [new_property.id],
                                        server_group_ids: [new_server_group.id] } }.to_json }
        let(:updated_server) { Server.where(name: new_name).first }

        subject { response.body }
        it { should have_json('number.id').with_value(updated_server.id) }
        it { should have_json('string.name').with_value(updated_server.name) }
        it { should have_json('string.dns').with_value(updated_server.dns) }
        it { should have_json('string.ip_address').with_value(updated_server.ip_address) }
        it { should have_json('string.os_platform').with_value(updated_server.os_platform) }
        it { should have_json('.environments .id').with_value(new_environment.id) }
        it { should have_json('.properties .id').with_value(new_property.id) }
        it { should have_json('.server_groups .id').with_value(new_server_group.id) }
      end

      it_behaves_like "successful request", type: :xml, method: :put, status: 202 do
        let(:new_name) { "Server_xml_new" }
        let(:new_dns) { "host_xml_new.streamstep.com" }
        let(:new_ip_address) { "192.168.0.3" }
        let(:new_os_platform) { "centos5" }
        let(:params) { { name: new_name,
                         dns: new_dns,
                         ip_address: new_ip_address,
                         os_platform: new_os_platform,
                         environment_ids: [new_environment.id],
                         property_ids: [new_property.id],
                         server_group_ids: [new_server_group.id] }.to_xml(root: xml_root) }
        let(:updated_server) { Server.where(name: new_name).first }

        subject { response.body }
        it { should have_xpath('/server/id').with_text(updated_server.id) }
        it { should have_xpath('/server/dns').with_text(updated_server.dns) }
        it { should have_xpath('/server/name').with_text(updated_server.name) }
        it { should have_xpath('/server/ip-address').with_text(updated_server.ip_address) }
        it { should have_xpath('/server/os-platform').with_text(updated_server.os_platform) }
        it { should have_xpath('/server/environments/environment/id').with_text(new_environment.id) }
        it { should have_xpath('/server/properties/property/id').with_text(new_property.id) }
        it { should have_xpath('/server/server-groups/server-group/id').with_text(new_server_group.id) }
      end

      it_behaves_like 'change `active` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) do
          create(:server, name: 'Used_name')
          @server = create(:server)
        end

        let(:url)  { "#{base_url}/#{@server.id}/?token=#{@user.api_key}" }
        let(:param) { {:name => 'Used_name'} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @server = create(:server)
        Server.stub(:find).with(@server.id).and_return @server
      end

      let(:url) {"#{base_url}/#{@server.id}?token=#{@user.api_key}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @server.id }.to_json
          params_xml        = create_xml {|xml| xml.id @server.id}
          params            = eval "params_#{mimetype}"
          mimetype_headers  = eval "#{mimetype}_headers"

          delete url, params, mimetype_headers

          response.status.should == 202
          @server.active.should == false
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

  context 'with no existing servers' do

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