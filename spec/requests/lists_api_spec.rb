require 'spec_helper'

base_url = '/v1/lists'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :list }
  let(:xml_root) { 'list' }

  before(:all) do
    @user = create(:user)
    @token = @user.api_key
  end

  context 'with existing lists and valid api key' do
    before(:each) do
    end

    let(:url) { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @list_1 = create(:list)
        @list_2 = create(:list, :name => 'Acquirit qui tuetur')
        @list_3 = create(:list, :name => 'mad')
        @list_3.toggle_archive
        @list_3.reload

        @unarchived_list_ids = [@list_2.id, @list_1.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all lists except archived(by default)' do
          jget

          should have_json('number.id').with_values(@unarchived_list_ids)
        end

        it 'should return all lists except archived' do
          param = {:filters => {:unarchived => true}}

          jget param

          should have_json('number.id').with_values(@unarchived_list_ids)
        end

        it 'should return all lists  archived' do
          param = {:filters => {:archived => true}}

          jget param

          should have_json('number.id').with_values([@list_3.id])
        end

        it 'should return all lists' do
          param = {:filters => {:archived => true, :unarchived => true}}

          jget param

          should have_json('number.id').with_values([@list_3.id] + @unarchived_list_ids)
        end

        it 'should return all archived lists' do
          param = {:filters => {:archived => true, :unarchived => false}}

          jget param

          should have_json('number.id').with_value(@list_3.id)
        end

        it 'should return list by name' do
          param = {:filters => {:name => 'Acquirit qui tuetur'}}

          jget param

          should have_json('number.id').with_value(@list_2.id)
        end

        it 'should not return archived list by name' do
          param = {:filters => {:name => @list_3.name}}

          jget param

          should == " "
        end

        it 'should return nothing' do
          param = {:filters => {:unarchived => false}}

          jget param

          response.status.should == 404
          should == " "
        end

        it 'should return archived list by name if it is specified' do
          param = {:filters => {:name => @list_3.name, :archived => true}}

          jget param

          should have_json('number.id').with_value(@list_3.id)
        end
      end

      context 'XML' do
        let(:xml_root) { 'lists/list' }

        subject { response.body }

        it 'should return all lists except archived(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_list_ids)
        end

        it 'should return all lists except archived' do
          param = {:filters => {:unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_list_ids)
        end

        it 'should return all lists  archived' do
          param = {:filters => {:archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@list_3.id])
        end

        it 'should return all lists' do
          param = {:filters => {:archived => true, :unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@list_3.id] + @unarchived_list_ids)
        end

        it 'should return all archived lists' do
          param = {:filters => {:archived => true, :unarchived => false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@list_3.id)
        end

        it 'should return list by name' do
          param = {:filters => {:name => 'Acquirit qui tuetur'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@list_2.id)
        end

        it 'should not return archived list by name if that was not specified' do
          param = {:filters => {:name => @list_3.name}}

          xget param

          response.status.should == 404
          should == " "
        end

        it 'should return archived list by name if it is specified' do
          param = {:filters => {:name => @list_3.name, :archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@list_3.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @list_1 = create(:list)
        @list_2 = create(:list)
      end

      context 'JSON' do
        let(:url) { "#{base_url}/#{@list_1.id}?token=#{@token}" }

        subject { response.body }

        it 'should return list' do
          jget

          should have_json('number.id').with_value(@list_1.id)
        end
      end

      context 'XML' do
        let(:url) { "#{base_url}/#{@list_2.id}?token=#{@token}" }

        subject { response.body }

        it 'should return list' do
          xget

          should have_xpath('list/id').with_text(@list_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      before(:each) do
        @list_item_1 = create(:list_item)
        @list_item_2 = create(:list_item)
      end

      let(:created_by_id) { @user.id }
      let(:list_item_ids) { [@list_item_1.id, @list_item_2.id] }
      let(:is_text) { true }
      let(:list_items_attributes) { {list_items_attributes: {id: @list_item_1.id, value_text: 'permanent'}} }

      it_behaves_like "successful request", type: :json, method: :post, status: 201 do
        let(:name) { "List_json" }
        let(:params) { {json_root => {name: name,
                                      created_by_id: created_by_id,
                                      is_text: is_text,
                                      list_items_attributes: list_items_attributes,
                                      list_item_ids: list_item_ids}}.to_json }
        let(:added_list) { List.where(name: name).first }

        subject { response.body }
        it { should have_json('number.id').with_value(added_list.id) }
        it { should have_json('string.name').with_value(added_list.name) }
        it { should have_json('number.created_by_id').with_value(added_list.created_by_id) }
        it { should have_json('boolean.is_text').with_value(added_list.is_text) }
        it { should have_json('.list_items .id').with_values(added_list.list_item_ids) }
      end

      it_behaves_like "successful request", type: :xml, method: :post, status: 201 do
        let(:name) { "List_xml" }
        let(:params) { {name: name,
                        created_by_id: created_by_id,
                        is_text: is_text,
                        list_items_attributes: list_items_attributes,
                        list_item_ids: list_item_ids}.to_xml(root: xml_root) }
        let(:added_list) { List.where(name: name).first }

        subject { response.body }
        it { should have_xpath('list/id').with_text(added_list.id) }
        it { should have_xpath('list/name').with_text(added_list.name) }
        it { should have_xpath('list/created-by-id').with_text(added_list.created_by_id) }
        it { should have_xpath('list/is-text').with_text(added_list.is_text) }
        it { should have_xpath('list/list-items/list-item/id').with_texts(list_item_ids) }
      end

      it_behaves_like 'creating request with params that fails validation' do
        before(:each) { @list = create(:list) }

        let(:param) { {:name => List.last.name} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      before(:each) do
        @list_put = create(:list)
        @list_item_put_1 = create(:list_item)
        @list_item_put_2 = create(:list_item)
        @user_put = create(:user)
      end

      let(:created_by_id) { @user_put.id }
      let(:list_item_ids) { [@list_item_put_1.id, @list_item_put_2.id] }
      let(:is_text) { true }
      let(:url) { "#{base_url}/#{@list_put.id}/?token=#{@token}" }

      it_behaves_like "successful request", type: :json, method: :put, status: 202 do
        let(:name) { "List_json_put" }
        let(:list_items_attributes) { {list_items_attributes: {id: @list_item_put_1.id, value_text: 'permanent'}} }
        let(:params) { {json_root => {name: name,
                                      created_by_id: created_by_id,
                                      is_text: is_text,
                                      list_items_attributes: list_items_attributes,
                                      list_item_ids: list_item_ids}}.to_json }
        let(:updated_list) { List.where(name: name).first }

        subject { response.body }
        it { should have_json('number.id').with_value(updated_list.id) }
        it { should have_json('string.name').with_value(updated_list.name) }
        it { should have_json('number.created_by_id').with_value(updated_list.created_by_id) }
        it { should have_json('boolean.is_text').with_value(updated_list.is_text) }
        it { should have_json('.list_items .id').with_values(updated_list.list_item_ids) }
      end

      it_behaves_like "successful request", type: :xml, method: :put, status: 202 do
        let(:name) { "List_xml_put" }
        let(:list_items_attributes) { {list_items_attributes: {id: @list_item_put_1.id, value_text: 'permanent'}} }
        let(:params) { {name: name,
                        created_by_id: created_by_id,
                        is_text: is_text,
                        list_items_attributes: list_items_attributes,
                        list_item_ids: list_item_ids}.to_xml(root: xml_root) }
        let(:updated_list) { List.where(name: name).first }

        subject { response.body }
        it { should have_xpath('list/id').with_text(updated_list.id) }
        it { should have_xpath('list/name').with_text(updated_list.name) }
        it { should have_xpath('list/created-by-id').with_text(updated_list.created_by_id) }
        it { should have_xpath('list/is-text').with_text(updated_list.is_text) }
        it { should have_xpath('list/list-items/list-item/id').with_texts(list_item_ids) }
      end

      it_behaves_like 'with `toggle_archive` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) do
          @existing_list = create(:list)
          @list = create(:list)
        end

        let(:url) { "#{base_url}/#{@list.id}/?token=#{@token}" }
        let(:param) { {:name => @existing_list.name} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @list = create(:list)
        List.stub(:find).with(@list.id).and_return @list
        @list.should_receive(:try).with(:destroy).and_return true
      end

      let(:list_id) { @list.id }
      let(:url) { "#{base_url}/#{@list.id}?token=#{@token}" }


      tested_formats.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json = {id: @list.id}.to_json
          params_xml = create_xml { |xml| xml.id @list.id }
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

  context 'with no existing lists' do

    before(:all) do
      # make sure there's none of lists
      #List.destroy_all
    end

    let(:token) { @token }

    methods_urls_for_404 = {
        get: ["#{base_url}", "#{base_url}/1"],
        put: ["#{base_url}/1"],
        delete: ["#{base_url}/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_404, response_code: 404, mimetypes: mimetypes
  end


end