require 'spec_helper'

describe 'v1/work_tasks' do
  before(:all) {
    @user = create(:user)
  }
  let(:token) { @user.api_key }
  let(:base_url) { '/v1/work_tasks' }
  let(:params) { {} }
  let(:json_root) { :work_task }
  let(:xml_root) { 'work-task' }

  context 'when no work tasks exist' do
    let(:url) { "#{base_url}?token=#{token}" }
    tested_formats.each do |type|
      it_behaves_like 'successful request', status: 404, type: type
    end
    context 'when trying to reach invalid id' do
      let(:url) { "#{base_url}/50?token=#{token}" }
      %w(get put delete).each do |method|
        context "#{method.upcase} /{{id}}" do
          tested_formats.each do |type|
            it_behaves_like 'successful request', status: 404, type: type, method: method.to_sym
          end
        end
      end
    end
    describe 'POST /' do
      it_behaves_like 'successful request', status: 201, method: :post, type: :json do
        let(:params) { {json_root => {name: 'json work task'}}.to_json }
        specify { response.body.should have_json('number.id') }
        specify { response.body.should have_json('string.name').with_value('json work task') }
      end
      it_behaves_like 'successful request', status: 201, method: :post, type: :xml do
        let(:params) { {name: 'xml work task'}.to_xml(root: xml_root) }
        specify { response.body.should have_xpath('work-task/id') }
        specify { response.body.should have_xpath('work-task/name').with_text('xml work task') }
      end
    end

    it_behaves_like 'creating request with params that fails validation' do
      before (:each) { @post_work_task = create(:work_task) }
      let(:param) { { :name => @post_work_task.name } }
    end

    it_behaves_like 'creating request with invalid params'
  end

  context 'when work task exists' do
    before(:each) {
      @wt1 = create(:work_task)
      @wt2 = create(:work_task, name: 'cool name')
      @wt3 = create(:work_task)
      @wt3.toggle_archive
    }
    let(:archived_id) { @wt3.id }
    let(:unarchived_ids) { [@wt1.id, @wt2.id] }
    let(:unarchived_names) { [@wt1.name, @wt2.name] }
    let(:unarchived_positions) { [@wt1.position, @wt2.position] }
    let(:all_ids) { [archived_id] + unarchived_ids }
    describe 'GET /' do
      let(:url) { "#{base_url}?token=#{token}" }
      let(:id_json_select) { ':root > object > number.id' }
      let(:id_xpath) { '/work-tasks/work-task/id' }
      it_behaves_like 'successful request', type: :json do
        subject { response.body }
        it { should have_json('object:first-child null.archive_number') }
        it { should have_json('object:first-child null.archived_at') }
        it { should have_json('object:first-child string.created_at') }
        it { should have_json('object:first-child string.updated_at') }
        it { should have_json('object:first-child array.steps') }
        it { should have_json(':root > object > number.id').with_values(unarchived_ids) }
        it { should have_json(':root > object > number.position').with_values(unarchived_positions) }
        it { should have_json(':root > object > string.name').with_values(unarchived_names) }
      end
      describe 'filtered by name' do
        let(:params) { {filters: {name: 'cool name'}} }
        it_behaves_like 'successful request', type: :json do
          specify { response.body.should have_json(id_json_select).with_value(@wt2.id) }
        end
        it_behaves_like 'successful request', type: :xml do
          specify { response.body.should have_xpath(id_xpath).with_text(@wt2.id) }
        end
      end
      describe 'archived' do
        let(:params) { {filters: {archived: true}} }
        it_behaves_like 'successful request', type: :json do
          specify { response.body.should have_json(id_json_select).with_value(archived_id) }
        end
        it_behaves_like 'successful request', type: :xml do
          specify { response.body.should have_xpath(id_xpath).with_text(archived_id) }
        end
      end
      describe 'unarchived' do
        let(:params) { {filters: {unarchived: true}} }
        it_behaves_like 'successful request', type: :json do
          it { response.body.should have_json(id_json_select).with_values(unarchived_ids) }
        end
        it_behaves_like 'successful request', type: :xml do
          specify { response.body.should have_xpath(id_xpath).with_texts(unarchived_ids) }
        end
      end
      describe 'unarchived+archived' do
        let(:params) { {filters: {archived: true, unarchived: true}} }
        it_behaves_like 'successful request', type: :json do
          specify { response.body.should have_json(id_json_select).with_values(all_ids) }
        end
        it_behaves_like 'successful request', type: :xml do
          specify { response.body.should have_xpath(id_xpath).with_texts(all_ids) }
        end
      end
    end

    describe 'PUT {{id}}/' do
      before(:each) { @wt_put = create(:work_task) }
      let(:url) { "#{base_url}/#{@wt_put.id}?token=#{@user.api_key}" }
      it_behaves_like 'successful request', status: 202, method: :put, type: :json do
        let(:params) { {json_root => {name: 'updated json name'}}.to_json }
        specify { response.body.should have_json('number.id') }
        specify { response.body.should have_json('string.name').with_value('updated json name') }
        specify { WorkTask.find(@wt_put.id).name.should == 'updated json name' }
      end
      it_behaves_like 'successful request', status: 202, method: :put, type: :xml do
        let(:params) { {name: 'updated xml name'}.to_xml(root: xml_root) }
        specify { response.body.should have_xpath('work-task/id') }
        specify { response.body.should have_xpath('work-task/name').with_text('updated xml name') }
        specify { WorkTask.find(@wt_put.id).name.should == 'updated xml name' }
      end

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) { @put_work_task = create(:work_task) }
        let(:param) { {:name => @put_work_task.name} }
      end

      it_behaves_like 'editing request with invalid params'

      it_behaves_like 'with `toggle_archive` param'
    end

    describe "DELETE {{id}}/" do
      context 'when trying to delete non-archived work task' do
        before(:each) { @wt_delete = create(:work_task) }
        tested_formats.each do |format|
          let(:url) { "#{base_url}/#{@wt_delete.id}?token=#{@user.api_key}" }
          it_behaves_like 'successful request', type: format, status: 412, method: :delete do
            specify { WorkTask.exists?(@wt_delete.id).should be_truthy }
          end
        end
      end
      context 'when trying to delete archived work task' do
        before(:each) do
          @wt_delete = create(:work_task)
          @wt_delete.archive
          @wt_delete.reload
        end
        let(:url) { "#{base_url}/#{@wt_delete.id}?token=#{@user.api_key}" }
        tested_formats.each do |format|
          it_behaves_like 'successful request', type: format, status: 202, method: :delete do
            specify { WorkTask.exists?(@wt_delete.id).should be_falsey }
          end
        end
      end
    end
  end
end
