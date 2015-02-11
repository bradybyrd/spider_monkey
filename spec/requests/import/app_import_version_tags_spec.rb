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

  describe 'import app xml with version tags' do
    let(:app_name) { "import_app_version_tags" }
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      let(:xml_content)   { File.open("spec/data/#{app_name}.xml", "r").read }
      let(:added_app)     { App.find_by_name(app_name) }
      let(:imported_hash) { Hash.from_xml(xml_content) }
      let(:params)        { xml_content }
      let(:version_tags)  { VersionTag.all.map(&:name) }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_app.name) }

      it 'has imported version tags' do
        imported_version_tags.each do |vt|
          expect(version_tags).to include(vt['name'])
        end
      end
    end
  end

  def imported_version_tags
    imported_hash['app_import']['app']['version_tags']
  end

end
