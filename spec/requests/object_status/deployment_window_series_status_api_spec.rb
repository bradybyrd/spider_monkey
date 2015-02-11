require 'spec_helper'

describe 'deployment window series with status api' do
  before :all do
    @user = create(:user)
  end

  let(:base_url) { '/v1/deployment_window/series' }
  let(:json_root) { :deployment_window_series }
  let(:xml_root) { 'deployment_window_series' }
  let(:params) { {token: @user.api_key} }
  let(:deployment_window_series) { create(:deployment_window_series) }
  subject { response }

  describe 'changes to draft from released' do
    let (:url) { "#{base_url}/#{deployment_window_series.id}?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :json, method: :put, status: 202 do
      let(:new_name)    { "JSON #{Time.now.to_i}" }
      let(:new_state)   { 'draft' }
      let(:obj_params)  { { name: new_name, aasm_state: new_state } }
      let(:params)      { { json_root => obj_params }.to_json }

      subject { response.body }
      it { is_expected.to have_json('string.name').with_value(new_name) }
      it { is_expected.to have_json('string.aasm_state').with_value(new_state) }
    end
  end

  describe 'failures from released state' do
    let (:url) { "#{base_url}/#{deployment_window_series.id}?token=#{@user.api_key}" }

    it_behaves_like 'editing request with params that fails validation' do
      let(:param) { { aasm_state: 'foo' } }
    end

    it_behaves_like 'editing request with params that fails validation' do
      let(:param) { { aasm_state: 'archived' } }
    end
  end

  describe 'changes from archived to retired' do
    before(:each) do
      deployment_window_series.update_attributes(aasm_state: 'retired')
      deployment_window_series.archival!
    end

    let (:url) { "#{base_url}/#{deployment_window_series.id}?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :put, status: 202 do
      let(:new_name)    { "XML #{Time.now.to_i}" }
      let(:new_state)   { 'retired' }
      let(:obj_params)  { { name: new_name, aasm_state: new_state } }
      let(:params)      { obj_params.to_xml(root: xml_root) }

      subject { response.body }
      it { is_expected.to have_xpath("series-item/name").with_text(new_name)  }
      it { is_expected.to have_xpath("series-item/aasm-state").with_text(new_state) }
    end
  end

  describe 'failures from archived state' do
    before(:each) do
      deployment_window_series.update_attributes(aasm_state: 'retired')
      deployment_window_series.archival!
    end
    let (:url) { "#{base_url}/#{deployment_window_series.id}?token=#{@user.api_key}" }

    # it_behaves_like 'editing request with params that fails validation' do
    #   let(:param) { { aasm_state: 'foo' } }
    # end

    it_behaves_like 'editing request with params that fails validation' do
      let(:param) { { aasm_state: 'draft' } }
    end
  end
end
