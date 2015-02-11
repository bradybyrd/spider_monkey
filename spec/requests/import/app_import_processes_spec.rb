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


  describe 'import app_import xml with processes' do
    app_name = "import_app_with_processes"
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      xml_content = File.open("spec/data/#{app_name}.xml", "r").read
      let(:added_app)     { App.where(name: app_name).first }
      let(:imported_hash) { Hash.from_xml(xml_content) }
      let(:params)        { xml_content }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_app.name) }

      it "has imported processes" do
        imported_processes.each do |xml_process|
          process = BusinessProcess.where(name: xml_process["name"]).first
          expect(process.label_color).to eq(xml_process["label_color"])
          expect(process.apps).to eq([added_app])
        end
      end

    end
  end

  private

  def imported_processes
    imported_hash["app_import"]["app"]["active_business_processes"]
  end

end
