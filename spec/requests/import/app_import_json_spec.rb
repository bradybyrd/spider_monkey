require 'spec_helper'

describe '/v1/apps', import_export: true do
  before :all do
    @user = create(:user)
    create(:team, name: '[default]')
  end

  let(:base_url) { '/v1/apps' }
  let(:json_root) { :app }
  let(:xml_root) { 'app' }
  let(:import_root) { 'app_import/app' }
  let(:params) { {token: @user.api_key} }
  subject { response }

  before { DeploymentWindow::SeriesBackgroundable.stub(:background).and_return(DeploymentWindow::SeriesBackgroundable) }

  describe 'import json app file' do
    let(:app_name) { 'import_app_json' }
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :json, method: :post, status: 201 do
      let(:json_content) { File.open("spec/data/#{app_name}.json", "r").read }
      let(:added_app)     { App.find_by_name(app_name) }
      let(:imported_hash) { JSON.parse(json_content) }
      let(:params)        { json_content }

      subject { response.body }
      it { is_expected.to have_json('string.name').with_value(added_app.name) }

    end
  end

end
