require 'spec_helper'

base_url = '/v1/server_groups'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :server_group }
  let(:xml_root) { 'server-group' }

  before :all do
    @user         = create(:user)
    @token        = @user.api_key
  end

  context 'with existing server_groups and valid api key' do
    before(:each)  do
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @sg_1 = create(:server_group)
        @sg_2 = create(:server_group, :name => 'Unum castigabis, centum emendabis')
        @sg_3 = create(:server_group, :name => 'mad', :active => false)

        @active_sg_ids = [@sg_2.id, @sg_1.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all server_groups except inactive(by default)' do
          jget

          should have_json('number.id').with_values(@active_sg_ids)
        end

        it 'should return all server_groups except inactive' do
          param   = {:filters => {:active => true}}

          jget param

          should have_json('number.id').with_values(@active_sg_ids)
        end

        it 'should return all server_groups inactive' do
          param   = {:filters => {:inactive => true}}

          jget param

          should have_json('number.id').with_values([@sg_3.id])
        end

        it 'should return all server_groups' do
          param   = {:filters => {:inactive => true, :active => true}}

          jget param

          should have_json('number.id').with_values([@sg_3.id] + @active_sg_ids)
        end

        it 'should return all inactive server_groups' do
          param   = {:filters => {:inactive => true, :active => false}}

          jget param

          should have_json('number.id').with_value(@sg_3.id)
        end

        it 'should return server_group by name' do
          param   = {:filters => {:name => 'Unum castigabis, centum emendabis'}}

          jget param

          should have_json('number.id').with_value(@sg_2.id)
        end

        it 'should not return inactive server_group by name' do
          param   = {:filters => {:name => 'mad'}}

          jget param

          should == " "
        end

        it 'should return inactive server_group by name if it is specified' do
          param   = {:filters => {:name => 'mad', :inactive => true}}

          jget param

          should have_json('number.id').with_value(@sg_3.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'server-groups/server-group'}

        subject { response.body }

        it 'should return all server-groups except inactive(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@active_sg_ids)
        end

        it 'should return all server-groups except inactive' do
          param   = {:filters => {:active => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@active_sg_ids)
        end

        it 'should return all server_groups inactive' do
          param   = {:filters => {:inactive => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@sg_3.id])
        end

        it 'should return all server-groups' do
          param   = {:filters => {:inactive => true, :active => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@sg_3.id] + @active_sg_ids)
        end

        it 'should return all inactive server-groups' do
          param   = {:filters => {:inactive => true, :active => false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@sg_3.id)
        end

        it 'should return server-group by name' do
          param   = {:filters => {:name => 'Unum castigabis, centum emendabis'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@sg_2.id)
        end

        it 'should not return inactive server-group by name if that was not specified' do
          param   = {:filters => {:name => 'mad'}}

          xget param

          should == " "
        end

        it 'should return inactive server-group by name if it is specified' do
          param   = {:filters => {:name => 'mad', :inactive => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@sg_3.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @sg_1 = create(:server_group)
        @sg_2 = create(:server_group)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@sg_1.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return server_group' do
          jget

          should have_json('number.id').with_value(@sg_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@sg_2.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return server-group' do
          xget

          should have_xpath('server-group/id').with_text(@sg_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      before :each do
        @server = create(:server)
        @environment = create(:environment)
        @server_aspect = create(:server_aspect)
      end

      let(:url) {"#{base_url}?token=#{@user.api_key}"}
      let(:description) { "json Server Group description" }
      let(:server_ids) { [@server.id] }
      let(:environment_ids) { [@environment.id] }
      let(:server_aspect_ids) { [@server_aspect.id] }

      it_behaves_like "successful request", type: :json, method: :post, status: 201 do
        let(:name) { "json_Server Group" }
        let(:params) { { json_root => { name: name,
                                        description: description,
                                        server_ids: server_ids,
                                        environment_ids: environment_ids,
                                        server_aspect_ids: server_aspect_ids } }.to_json }
        let(:added_server_group) { ServerGroup.where(name: name).first }

        subject { response.body }
        it { should have_json('number.id').with_value(added_server_group.id) }
        it { should have_json('string.name').with_value(added_server_group.name) }
        it { should have_json('string.description').with_value(added_server_group.description) }
        it { should have_json('.servers .id').with_value(added_server_group.servers.first.id) }
        it { should have_json('.environments .id').with_value(added_server_group.environments.first.id) }
        it { should have_json('.server_aspects .id').with_value(added_server_group.server_aspects.first.id) }
        it { should have_json('boolean.active').with_value(true) }
      end

      it_behaves_like "successful request", type: :xml, method: :post, status: 201 do
        let(:name) { "xml_Server Group" }
        let(:params) {  { name: name,
                          description: description,
                          server_ids: server_ids,
                          environment_ids: environment_ids,
                          server_aspect_ids: server_aspect_ids }.to_xml(root: xml_root) }
        let(:added_server_group) { ServerGroup.where(name: name).first }

        subject { response.body }
        it { should have_xpath('server-group/id').with_text(added_server_group.id) }
        it { should have_xpath('server-group/name').with_text(added_server_group.name) }
        it { should have_xpath('server-group/description').with_text(added_server_group.description) }
        it { should have_xpath('server-group/servers/server/id').with_text(added_server_group.servers.first.id) }
        it { should have_xpath('server-group/environments/environment/id').with_text(added_server_group.environments.first.id) }
        it { should have_xpath('server-group/server-aspects/server-aspect/id').with_text(added_server_group.server_aspects.first.id) }
        it { should have_xpath('server-group/active').with_text('true') }
      end

      it_behaves_like 'creating request with params that fails validation' do
        before(:each) { @server_group = create(:server_group) }

        let(:param) { {:name => ServerGroup.last.name} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      before :each do
        @server_group = create(:server_group)
        @server = create(:server)
        @environment = create(:environment)
        @server_aspect = create(:server_aspect)
      end

      let(:url) {"#{base_url}/#{@server_group.id}?token=#{@user.api_key}"}
      let(:description) { "json Server Group description" }
      let(:server_ids) { [@server.id] }
      let(:environment_ids) { [@environment.id] }
      let(:server_aspect_ids) { [@server_aspect.id] }

      it_behaves_like "successful request", type: :json, method: :put, status: 202 do
        let(:name) { "new_json_Server Group" }
        let(:params) { { json_root => { name: name,
                                        description: description,
                                        server_ids: server_ids,
                                        environment_ids: environment_ids,
                                        server_aspect_ids: server_aspect_ids } }.to_json }
        let(:added_server_group) { ServerGroup.where(name: name).first }

        subject { response.body }
        it { should have_json('number.id').with_value(added_server_group.id) }
        it { should have_json('string.name').with_value(added_server_group.name) }
        it { should have_json('string.description').with_value(added_server_group.description) }
        it { should have_json('.servers .id').with_value(added_server_group.servers.first.id) }
        it { should have_json('.environments .id').with_value(added_server_group.environments.first.id) }
        it { should have_json('.server_aspects .id').with_value(added_server_group.server_aspects.first.id) }
      end

      it_behaves_like "successful request", type: :xml, method: :put, status: 202 do
        let(:name) { "new_xml_Server Group" }
        let(:params) {  { name: name,
                          description: description,
                          server_ids: server_ids,
                          environment_ids: environment_ids,
                          server_aspect_ids: server_aspect_ids }.to_xml(root: xml_root) }
        let(:added_server_group) { ServerGroup.where(name: name).first }

        subject { response.body }
        it { should have_xpath('server-group/id').with_text(added_server_group.id) }
        it { should have_xpath('server-group/name').with_text(added_server_group.name) }
        it { should have_xpath('server-group/description').with_text(added_server_group.description) }
        it { should have_xpath('server-group/servers/server/id').with_text(added_server_group.servers.first.id) }
        it { should have_xpath('server-group/environments/environment/id').with_text(added_server_group.environments.first.id) }
        it { should have_xpath('server-group/server-aspects/server-aspect/id').with_text(added_server_group.server_aspects.first.id) }
      end

      it_behaves_like 'change `active` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) do
          create(:server_group, name: 'existing_name')
          @server_group = create(:server_group)
        end

        let(:url)  { "#{base_url}/#{@server_group.id}/?token=#{@user.api_key}" }
        let(:param) { {name: 'existing_name'} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @server_group = create(:server_group)
        ServerGroup.stub(:find).with(@server_group.id).and_return @server_group
      end

      let(:url) {"#{base_url}/#{@server_group.id}?token=#{@user.api_key}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @server_group.id }.to_json
          params_xml        = create_xml {|xml| xml.id @server_group.id}
          params            = eval "params_#{mimetype}"
          mimetype_headers  = eval "#{mimetype}_headers"

          delete url, params, mimetype_headers

          response.status.should == 202
          @server_group.active.should == false
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

  context 'with no existing server_groups' do

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