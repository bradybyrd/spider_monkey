require 'spec_helper'

describe 'testing /v1/project_servers' do
  base_url =  '/v1/project_servers'
  let(:base_url) { base_url }
  let(:json_root) { :project_server }
  let(:xml_root) { 'project_server' }

  before :all do
    @user         = create(:user)
    @token        = @user.api_key
  end

  context 'with existing project_servers and valid api key' do
    before(:each)  do
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @ps_1 = create(:project_server)
        @ps_2 = create(:project_server, :name => 'Veritatem dies aperit')
        @ps_3 = create(:project_server, :name => 'mad', :is_active => false)

        @active_ps_ids = [@ps_2.id, @ps_1.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all project_servers except inactive(by default)' do
          jget

          should have_json('number.id').with_values(@active_ps_ids)
        end

        it 'should return all project_servers except inactive' do
          param   = {:filters => {:active => true}}

          jget param

          should have_json('number.id').with_values(@active_ps_ids)
        end

        it 'should return all project_servers inactive' do
          param   = {:filters => {:inactive => true}}

          jget param

          should have_json('number.id').with_values([@ps_3.id])
        end

        it 'should return all project_servers' do
          param   = {:filters => {:inactive => true, :active => true}}

          jget param

          should have_json('number.id').with_values([@ps_3.id] + @active_ps_ids)
        end

        it 'should return all inactive project_servers' do
          param   = {:filters => {:inactive => true, :active => false}}

          jget param

          should have_json('number.id').with_value(@ps_3.id)
        end

        it 'should return project_server by name' do
          param   = {:filters => {:name => 'Veritatem dies aperit'}}

          jget param

          should have_json('number.id').with_value(@ps_2.id)
        end

        it 'should not return inactive project_server by name' do
          param   = {:filters => {:name => 'mad'}}

          jget param

          should == " "
        end

        it 'should return inactive project_server by name if it is specified' do
          param   = {:filters => {:name => 'mad', :inactive => true}}

          jget param

          should have_json('number.id').with_value(@ps_3.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'project-servers/project-server'}

        subject { response.body }

        it 'should return all project_servers except inactive(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@active_ps_ids)
        end

        it 'should return all project_servers except inactive' do
          param   = {:filters => {:active => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@active_ps_ids)
        end

        it 'should return all project_servers inactive' do
          param   = {:filters => {:inactive => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@ps_3.id])
        end

        it 'should return all project_servers' do
          param   = {:filters => {:inactive => true, :active => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@ps_3.id] + @active_ps_ids)
        end

        it 'should return all inactive project_servers' do
          param   = {:filters => {:inactive => true, :active => false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@ps_3.id)
        end

        it 'should return project_server by name' do
          param   = {:filters => {:name => 'Veritatem dies aperit'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@ps_2.id)
        end

        it 'should not return inactive project_server by name if that was not specified' do
          param   = {:filters => {:name => 'mad'}}

          xget param

          should == " "
        end

        it 'should return inactive project_server by name if it is specified' do
          param   = {:filters => {:name => 'mad', :inactive => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@ps_3.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @ps_1 = create(:project_server)
        @ps_2 = create(:project_server)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@ps_1.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return project_server' do
          jget

          should have_json('number.id').with_value(@ps_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@ps_2.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return project_server' do
          xget

          should have_xpath('project-server/id').with_text(@ps_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      let(:url) { "#{base_url}?token=#{@user.api_key}" }

      it_behaves_like "successful request", type: :json, method: :post, status: 201 do
        let(:name) { 'json_project_servers' }
        let(:server_name_id) { 1 }
        let(:server_url) { 'http://192.72.224.176:8080' }
        let(:username) { 'ss' }
        let(:params) { { json_root => { name: name,
                                        server_name_id: server_name_id,
                                        server_url: server_url,
                                        username: username } }.to_json }
        let(:added_project_server) { ProjectServer.where(name: name ).first }

        subject { response.body }
        it { should have_json('string.name').with_value(added_project_server.name) }
        it { should have_json('number.server_name_id').with_value(added_project_server.server_name_id) }
        it { should have_json('string.server_url').with_value(added_project_server.server_url) }
        it { should have_json('string.username').with_value(added_project_server.username) }
      end

      it_behaves_like "successful request", type: :xml, method: :post, status: 201 do
        let(:name) { 'xml_project_servers' }
        let(:server_name_id) { 3 }
        let(:server_url) { 'http://192.168.224.176:8080' }
        let(:username) { 'admin' }
        let(:params) { { name: name,
                         server_name_id: server_name_id,
                         server_url: server_url,
                         username: username }.to_xml(root: xml_root) }
        let(:added_project_server) { ProjectServer.where(name: name ).first }

        subject { response.body }
        it { should have_xpath('project-server/name').with_text(added_project_server.name) }
        it { should have_xpath('project-server/server-name-id').with_text(added_project_server.server_name_id) }
        it { should have_xpath('project-server/server-url').with_text(added_project_server.server_url) }
        it { should have_xpath('project-server/username').with_text(added_project_server.username) }
      end

      it_behaves_like 'creating request with params that fails validation' do
        let(:param) { { :server_name_id => nil, :name => nil, :server_url => nil, :username => nil } }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      before(:each) { @ps_put = create(:project_server) }

      let(:url) { "#{base_url}/#{@ps_put.id}?token=#{@user.api_key}" }

      it_behaves_like "successful request", type: :json, method: :put, status: 202 do
        let(:name) { 'new_json_project_servers' }
        let(:server_name_id) { 1 }
        let(:server_url) { 'http://192.88.224.176:8080' }
        let(:username) { 'ss_put' }
        let(:params) { { json_root => { name: name,
                                        server_name_id: server_name_id,
                                        server_url: server_url,
                                        username: username } }.to_json }
        let(:added_project_server) { ProjectServer.where(name: name ).first }

        subject { response.body }
        it { should have_json('string.name').with_value(added_project_server.name) }
        it { should have_json('number.server_name_id').with_value(added_project_server.server_name_id) }
        it { should have_json('string.server_url').with_value(added_project_server.server_url) }
        it { should have_json('string.username').with_value(added_project_server.username) }
      end

      it_behaves_like "successful request", type: :xml, method: :put, status: 202 do
        let(:name) { 'new_xml_project_servers' }
        let(:server_name_id) { 3 }
        let(:server_url) { 'http://192.76.224.176:8080' }
        let(:username) { 'admin_put' }
        let(:params) { { name: name,
                         server_name_id: server_name_id,
                         server_url: server_url,
                         username: username }.to_xml(root: xml_root) }
        let(:added_project_server) { ProjectServer.where(name: name ).first }

        subject { response.body }
        it { should have_xpath('project-server/name').with_text(added_project_server.name) }
        it { should have_xpath('project-server/server-name-id').with_text(added_project_server.server_name_id) }
        it { should have_xpath('project-server/server-url').with_text(added_project_server.server_url) }
        it { should have_xpath('project-server/username').with_text(added_project_server.username) }
      end

      it_behaves_like 'editing request with params that fails validation' do
        let(:param) { { :server_name_id => nil, :name => nil, :server_url => nil,:username => nil } }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @project_server = create(:project_server)
        ProjectServer.stub(:find).with(@project_server.id).and_return @project_server
      end

      let(:url) {"#{base_url}/#{@project_server.id}?token=#{@user.api_key}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @project_server.id }.to_json
          params_xml        = create_xml {|xml| xml.id @project_server.id}
          params            = eval "params_#{mimetype}"
          mimetype_headers  = eval "#{mimetype}_headers"

          delete url, params, mimetype_headers

          response.status.should == 202
          @project_server.is_active.should == false
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

  context 'with no existing project_servers' do

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