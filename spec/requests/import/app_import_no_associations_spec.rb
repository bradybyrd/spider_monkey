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

  describe 'import app xml with no associated objects' do
    app_name = "import_app_blank"
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      xml_content = File.open("spec/data/#{app_name}.xml", "r").read
      let(:added_app)     { App.find_by_name(app_name) }
      let(:imported_hash) { Hash.from_xml(xml_content) }
      let(:params)        { xml_content }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_app.name) }
    end
  end

end
