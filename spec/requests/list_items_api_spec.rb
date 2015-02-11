require "spec_helper"
describe 'v1/list_items' do
  before(:all) { @user = User.first || create(:user) }
  let(:base_url) { "v1/list_items" }
  let(:json_root) { :list_item }
  let(:xml_root) { 'list-item' }

  let(:params) { {token: @user.api_key} }
  subject { response }

  describe 'get v1/list_items' do
    before(:each) { @list_item = ListItem.first || create(:list_item) }
    let(:url) { "#{base_url}" }
    let(:list_items_ids) {ListItem.pluck(:id)}

    it_behaves_like "successful request", type: :json do
      subject { response.body }
      it { should have_json(':root > object > number.id').with_values(list_items_ids) }
    end

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('/list-items/list-item/id').with_texts(list_items_ids) }
    end

  end

  describe 'get v1/list_items[id]' do
    before(:each) { @list_item = ListItem.first || create(:list_item) }

    let(:url) { "#{base_url}/#{@list_item.id}" }

    it_behaves_like "successful request", type: :json do
      subject { response.body }
      it { should have_json('number.id').with_value(@list_item.id) }
      it { should have_json('string.value_text').with_value(@list_item.value_text) }
      it { should have_json('.list .id').with_value(@list_item.list_id) }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }
    end

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('/list-item/id').with_text(@list_item.id) }
      it { should have_xpath('/list-item/value-text').with_text(@list_item.value_text) }
      it { should have_xpath('/list-item/list/id').with_text(@list_item.list_id) }
      it { should have_xpath('/list-item/created-at') }
      it { should have_xpath('/list-item/updated-at') }
    end
  end

  describe 'post v1/list_items' do
    before(:each) { @list = List.first || create(:list) }
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like "successful request", type: :json, method: :post, status: 201 do
      let(:value_text) { "json_permanent" }
      let(:list_id) { @list.id }
      let(:params) { {json_root => {value_text: value_text, list_id: list_id}}.to_json }
      let(:new_list_item) { ListItem.where(value_text: value_text).first }

      subject { response.body }
      it { should have_json('number.id').with_value(new_list_item.id) }
      it { should have_json('string.value_text').with_value(new_list_item.value_text) }
      it { should have_json('.list .id').with_value(new_list_item.list_id) }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }
    end

    it_behaves_like "successful request", type: :xml, method: :post, status: 201 do
      let(:value_text) { "xml_permanent" }
      let(:list_id) { @list.id }
      let(:params) { {value_text: value_text, list_id: list_id}.to_xml(root: xml_root) }
      let(:new_list_item) { ListItem.where(value_text: value_text).first }

      subject { response.body }
      it { should have_xpath('/list-item/id').with_text(new_list_item.id) }
      it { should have_xpath('/list-item/value-text').with_text(new_list_item.value_text) }
      it { should have_xpath('/list-item/list/id').with_text(new_list_item.list_id) }
      it { should have_xpath('/list-item/created-at') }
      it { should have_xpath('/list-item/updated-at') }
    end

    it_behaves_like 'creating request with params that fails validation' do
      let(:param) { {:value_num => 'text'} }
    end

    it_behaves_like 'creating request with invalid params'
  end

  describe 'put v1/list_items[id]' do
    before :all do
      @list_item = ListItem.first || create(:list_item)
      @list = List.first || create(:list)
    end

    let(:url) { "#{base_url}/#{@list_item.id}/?token=#{@user.api_key}" }

    it_behaves_like "successful request", type: :json, method: :put, status: 202 do
      let(:new_value_text) { "new_json_permanent" }
      let(:new_list_id) { @list.id }
      let(:params) { {json_root => {value_text: new_value_text, list_id: new_list_id}}.to_json }
      let(:updated_list_item) { ListItem.where(value_text: new_value_text).first }

      subject { response.body }
      it { should have_json('number.id').with_value(updated_list_item.id) }
      it { should have_json('string.value_text').with_value(updated_list_item.value_text) }
      it { should have_json('.list .id').with_value(updated_list_item.list_id) }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }
    end

    it_behaves_like "successful request", type: :xml, method: :put, status: 202 do
      let(:new_value_text) { "new_xml_permanent" }
      let(:new_list_id) { @list.id }
      let(:params) { {value_text: new_value_text, list_id: new_list_id}.to_xml(root: xml_root) }
      let(:updated_list_item) { ListItem.where(value_text: new_value_text).first }

      subject { response.body }
      it { should have_xpath('/list-item/id').with_text(updated_list_item.id) }
      it { should have_xpath('/list-item/value-text').with_text(updated_list_item.value_text) }
      it { should have_xpath('/list-item/list/id').with_text(updated_list_item.list_id) }
      it { should have_xpath('/list-item/created-at') }
      it { should have_xpath('/list-item/updated-at') }
    end

    it_behaves_like 'with `toggle_archive` param'

    it_behaves_like 'editing request with params that fails validation' do
      before(:each) do
        @list_item = create(:list_item)
      end

      let(:url)  { "#{base_url}/#{@list_item.id}/?token=#{@user.api_key}" }
      let(:param) { {:value_num => 'text'} }
    end

    it_behaves_like 'editing request with invalid params'
  end

  describe 'delete v1/list_items[id]' do
    types = ['json', 'xml']

    types.each do |type|
      context 'when trying to delete non-archived list_item' do
        before(:each) { @list_item = create(:list_item) }
        let(:url) { "#{base_url}/#{@list_item.id}/?token=#{@user.api_key}" }
        it_behaves_like "successful request", type: type, method: :delete, status: 412 do
          let(:params) { {} }
          it { ListItem.exists?(@list_item.id).should be_truthy }
        end
      end
    end

    types.each do |type|
      context 'when trying to delete archived list_item' do
        before(:each) { @list_item = create(:list_item) { |item| item.toggle_archive } }
        let(:url) { "#{base_url}/#{@list_item.id}/?token=#{@user.api_key}" }
        it_behaves_like "successful request", type: type, method: :delete, status: 202 do
          let(:params) { {} }
          it { ListItem.exists?(@list_item.id).should be_falsey }
        end
      end
    end
  end
end