require 'spec_helper'

describe '/v1/apps', import_export: true do
  before :all do
    @user = create(:user)
    create(:team, name: '[default]')
  end

  let(:base_url) { '/v1/apps' }
  let(:xml_root) { 'app' }
  let(:params) { {token: @user.api_key} }
  subject { response }

  describe 'import app with duplicate aspects fails validation' do
    let(:app_name) { "import_app_server_aspect" }
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 422 do
      let(:xml_content)   { File.open("spec/data/#{app_name}.xml", "r").read }
      let(:params)        { xml_content }
    end
  end

end
