require 'spec_helper'

base_url =  '/v1/request_templates'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :request_template }
  let(:xml_root) { 'request-template' }

  before(:all) do
    @user   = create(:user)
    @token  = @user.api_key
  end

  context 'with existing request_templates and valid api key' do
    before(:each) do
      User.current_user = @user
      @request      = create(:request_with_app)
      @environment  = @request.environment
      @app          = @request.apps.first
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @time = Time.parse('11:05')
        @rt_1 = create(:request_template)
        @rt_2 = create(:request_template, request: @request, name: 'Usus magister est optimus', parent_id: @rt_1.id, recur_time: @time)
        @rt_3 = create(:request_template, name: 'mad name', aasm_state: 'retired')
        @rt_3.toggle_archive
        @rt_3.reload

        @unarchived_rt_ids = [@rt_2.id, @rt_1.id]
      end

      context 'JSON' do
        let(:json_root) {'array:root > object'}
        subject { response.body }

        it 'should return all request_templates except archived(by default)' do
          jget

          should have_json("#{json_root} > number.id").with_values(@unarchived_rt_ids)
        end

        it 'should return all request_templates except archived' do
          param   = {filters: {unarchived: true}}

          jget param

          should have_json("#{json_root} > number.id").with_values(@unarchived_rt_ids)
        end

        it 'should return all request_templates archived' do
          param   = {filters: {archived: true}}

          jget param

          should have_json("#{json_root} > number.id").with_values([@rt_3.id])
        end

        it 'should return all request_templates' do
          param   = {filters: {archived: true, unarchived: true}}

          jget param

          should have_json("#{json_root} > number.id").with_values([@rt_3.id] + @unarchived_rt_ids)
        end

        it 'should return all archived request_templates' do
          param   = {filters: {archived: true, unarchived: false}}

          jget param

          should have_json('number.id').with_value(@rt_3.id)
        end

        it 'should return request_template by name' do
          param   = {filters: {name: 'Usus magister est optimus'}}

          jget param

          should have_json('number.id').with_value(@rt_2.id)
        end

        it 'should not return archived request_template by name' do
          param   = {filters: {name: @rt_3.name}}

          jget param

          should == ' '
        end

        it 'should return archived request_template by name if it is specified' do
          param   = {filters: {name: @rt_3.name, archived: true}}

          jget param

          should have_json('number.id').with_value(@rt_3.id)
        end

        it 'should return archived request_template by `name`, `parent_id`, `environment_id`, `app_id`, `recur_time`' do
          param   = {filters: {name: 'Usus magister est optimus',
                               parent_id: @rt_1.id,
                               environment_id: @environment.id,
                               app_id: @app.id,
                               recur_time: @time}
          }

          jget param

          should have_json("#{json_root} > number.id").with_values([@rt_2.id])
        end
      end

      context 'XML' do
        let(:xml_root) {'request-templates/request-template'}

        subject { response.body }

        it 'should return all request-templates except archived(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_rt_ids)
        end

        it 'should return all request-templates except archived' do
          param   = {filters: {unarchived: true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_rt_ids)
        end

        it 'should return all request_templates archived' do
          param   = {filters: {archived: true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@rt_3.id])
        end

        it 'should return all request-templates' do
          param   = {filters: {archived: true, unarchived: true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@rt_3.id] + @unarchived_rt_ids)
        end

        it 'should return all archived request-templates' do
          param   = {filters: {archived: true, unarchived: false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@rt_3.id)
        end

        it 'should return request-template by name' do
          param   = {filters: {name: 'Usus magister est optimus'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@rt_2.id)
        end

        it 'should not return archived request-template by name if that was not specified' do
          param   = {filters: {name: @rt_3.name}}

          xget param

          should == ' '
        end

        it 'should return archived request-template by name if it is specified' do
          param   = {filters: {name: @rt_3.name, archived: true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@rt_3.id)
        end

        it 'should return archived request_template by `name`, `parent_id`, `environment_id`, `app_id`, `recur_time`' do
          param   = {filters: {name: 'Usus magister est optimus',
                               parent_id: @rt_1.id,
                               environment_id: @environment.id,
                               app_id: @app.id,
                               recur_time: @time}
          }

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@rt_2.id])
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @rt_1 = create(:request_template)
        @rt_2 = create(:request_template)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@rt_1.id}?token=#{@token}"}

        subject { response.body }

        it 'should return request_template' do
          jget

          should have_json('number.id').with_value(@rt_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@rt_2.id}?token=#{@token}"}

        subject { response.body }

        it 'should return request-template' do
          xget

          should have_xpath('request-template/id').with_text(@rt_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      before :each do
        @request_post = create(:request)
        @team_post = create(:team)
      end

      let(:url) {"#{base_url}?token=#{@token}"}
      let(:request_id_to_clone) { @request_post.id }
      let(:recur_time) { '2:00 PM' }
      let(:team_id) { @team_post.id }
      let(:parent_id) { @request_post.id }

      it_behaves_like 'successful request', type: :json, method: :post, status: 201 do
        let(:name) { 'json_Request Template' }
        let(:params) { { json_root => { name: name,
                                        request_id_to_clone: request_id_to_clone,
                                        recur_time: recur_time,
                                        team_id: team_id,
                                        parent_id: parent_id } }.to_json }
        let(:added_request_template) { RequestTemplate.where(name: name).first }

        subject { response.body }
        it { should have_json('number.id').with_value(added_request_template.id) }
        it { should have_json('string.name').with_value(added_request_template.name) }
        it { should have_json('number.team_id').with_value(added_request_template.team_id) }
        it { should have_json('number.parent_id').with_value(added_request_template.parent_id) }
        it { should have_json('string.recur_time') }
      end

      it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
        let(:name) { 'xml_Request Template' }
        let(:params) { { name: name,
                         request_id_to_clone: request_id_to_clone,
                         recur_time: recur_time,
                         team_id: team_id,
                         parent_id: parent_id }.to_xml(root: xml_root) }
        let(:added_request_template) { RequestTemplate.where(name: name).first }

        subject { response.body }
        it { should have_xpath('request-template/id').with_text(added_request_template.id) }
        it { should have_xpath('request-template/name').with_text(added_request_template.name) }
        it { should have_xpath('request-template/team-id').with_text(added_request_template.team_id) }
        it { should have_xpath('request-template/parent-id').with_text(added_request_template.parent_id) }
        it { should have_xpath('request-template/recur-time') }
      end

      it_behaves_like 'creating request with params that fails validation' do
        let(:param) { { name: nil, request_id_to_clone: nil } }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      before :each do
        @request_template = create(:request_template)
        @request_put = create(:request)
        @team_put = create(:team)
      end

      let(:url) {"#{base_url}/#{@request_template.id}?token=#{@token}"}
      let(:request_id_to_clone) { @request_put.id }
      let(:recur_time) { '4:00 PM' }
      let(:team_id) { @team_put.id }
      let(:parent_id) { @request_put.id }

      it_behaves_like 'successful request', type: :json, method: :put, status: 202 do
        let(:name) { 'new_json_Request Template' }
        let(:params) { { json_root => { name: name,
                                        request_id_to_clone: request_id_to_clone,
                                        recur_time: recur_time,
                                        team_id: team_id,
                                        parent_id: parent_id } }.to_json }
        let(:updated_request_template) { RequestTemplate.where(name: name).first }

        subject { response.body }
        it { should have_json('number.id').with_value(updated_request_template.id) }
        it { should have_json('string.name').with_value(updated_request_template.name) }
        it { should have_json('number.team_id').with_value(updated_request_template.team_id) }
        it { should have_json('number.parent_id').with_value(updated_request_template.parent_id) }
        it { should have_json('string.recur_time') }
      end

      it_behaves_like 'successful request', type: :xml, method: :put, status: 202 do
        let(:name) { 'new_xml_Request Template' }
        let(:params) { { name: name,
                         request_id_to_clone: request_id_to_clone,
                         recur_time: recur_time,
                         team_id: team_id,
                         parent_id: parent_id }.to_xml(root: xml_root) }
        let(:updated_request_template) { RequestTemplate.where(name: name).first }

        subject { response.body }
        it { should have_xpath('request-template/id').with_text(updated_request_template.id) }
        it { should have_xpath('request-template/name').with_text(updated_request_template.name) }
        it { should have_xpath('request-template/team-id').with_text(updated_request_template.team_id) }
        it { should have_xpath('request-template/parent-id').with_text(updated_request_template.parent_id) }
        it { should have_xpath('request-template/recur-time') }
      end

      it_behaves_like 'editing request with params that fails validation' do
        let(:param) { { name: nil, request_id_to_clone: nil } }
      end

      it_behaves_like 'editing request with invalid params'

      it_behaves_like 'with `toggle_archive` param'
    end

    describe "DELETE #{base_url}/[id]" do
      before :each do
        @request_template = create(:request_template)
      end

      before :each do
        RequestTemplate.stub(:find).with(@request_template.id).and_return @request_template
        @request_template.should_receive(:try).with(:destroy).and_return true
      end

      let(:url) {"#{base_url}/#{@request_template.id}?token=#{@token}"}

      mimetypes = %w(json xml)
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @request_template.id }.to_json
          params_xml        = create_xml {|xml| xml.id @request_template.id}
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

    test_batch_of_requests methods_urls_for_403, response_code: 403
  end

  context 'with no existing request_templates' do
    before :each do
      # make sure there's none of request_templates
      RequestTemplate.delete_all
    end

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
