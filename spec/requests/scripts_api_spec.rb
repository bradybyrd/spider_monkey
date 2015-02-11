require 'spec_helper'

describe V1::ScriptsController do
  base_url = '/v1/scripts'
  let(:json_root) { :script }

  before(:each) do
    @user = create(:user)
    @token = @user.api_key
  end
  let(:url) { "#{base_url}?token=#{@token}" }

  describe "GET #{base_url}" do
    before(:each) do
      @script_1 = create(:general_script, aasm_state: 'draft')
      @script_2 = create(:resource_automation_script, aasm_state: 'draft')
      @script_ids = [@script_2.id, @script_1.id]
    end

    context 'JSON' do
      let(:json_root) { 'array:root > object' }
      subject { response.body }

      it 'should return all scripts' do
        jget
        is_expected.to have_json("#{json_root} > number.id").with_values(@script_ids)
      end
    end

  end
end

