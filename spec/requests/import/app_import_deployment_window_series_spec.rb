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


  describe 'import xml with allow deployment windows' do
    let(:app_name) { 'import_app_with_deployment_window_series' }
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      let(:xml_content) { File.open("spec/data/#{app_name}.xml", "r").read }
      let(:added_app)     { App.find_by_name(app_name) }
      let(:imported_hash) { Hash.from_xml(xml_content) }
      let(:params)        { xml_content }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }

      it "has imported deployment windows" do
        imported_environments.each do |xml_env|
          env = Environment.find_by_name(xml_env["name"])
          if xml_env["active_deployment_window_series"]
            xml_env["active_deployment_window_series"].each do |xml_dws|
              dws = DeploymentWindow::Series.find_by_name(xml_dws["name"])
              expect(dws.environment_names).to include(env.name)
            end
          end
        end
      end
    end
  end

  describe 'import xml with prevent deployment windows' do
    let(:app_name) { 'app_with_prevents' }
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      let(:xml_content) { File.open("spec/data/#{app_name}.xml", "r").read }
      let(:added_app)     { App.find_by_name(app_name) }
      let(:imported_hash) { Hash.from_xml(xml_content) }
      let(:params)        { xml_content }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }

      it "has imported deployment windows" do
        imported_environments.each do |xml_env|
          env = Environment.find_by_name(xml_env["name"])
          if xml_env["active_deployment_window_series"]
            xml_env["active_deployment_window_series"].each do |xml_dws|
              dws = DeploymentWindow::Series.find_by_name(xml_dws["name"])
              expect(dws.environment_names).to include(env.name)
            end
          end
        end
      end
    end
  end

  private

  def imported_environments
    imported_hash["app_import"]["app"]["environments"]
  end

end
