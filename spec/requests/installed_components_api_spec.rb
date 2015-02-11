require 'spec_helper'

describe '/v1/installed_components' do
  before :all do
    @user = create(:user)
  end

  let(:base_url) { 'v1/installed_components' }
  let(:params) { {token: @user.api_key} }
  let(:json_root) { :installed_component }
  let(:xml_root) { 'installed-component' }

  describe 'GET /v1/installed_components' do
    let(:xml_root) {'installed-components/installed-component'}
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    describe 'without filters' do
      before(:each) do
        @installed_component_1 = create(:installed_component)
        @installed_component_2 = create(:installed_component)
      end

      let(:ids) { [@installed_component_1.id, @installed_component_2.id] }
      let(:application_component_ids) { [@installed_component_1.application_component.id, @installed_component_2.application_component.id] }
      let(:application_environment_ids) { [@installed_component_1.application_environment.id, @installed_component_2.application_environment.id] }

      it_behaves_like 'successful request', type: :json do
        subject { response.body }
        it { should have_json(':root > object > number.id').with_values(ids) }
        it { should have_json(':root > object > object.application_component > number.id').with_values(application_component_ids) }
        it { should have_json(':root > object > object.application_environment > number.id').with_values(application_environment_ids) }

      end

      it_behaves_like 'successful request', type: :xml do
        subject { response.body }
        it { should have_xpath("#{xml_root}/id").with_texts(ids) }
        it { should have_xpath("#{xml_root}/application-component/id").with_texts(application_component_ids) }
        it { should have_xpath("#{xml_root}/application-environment/id").with_texts(application_environment_ids) }
      end
    end

    describe 'with filters' do
      before :each do
        @server_group = create(:server_group)
        @installed_component = create(:installed_component, server_group: @server_group)
      end

      describe 'filtered by app_id' do
        let(:params) { {filters: {app_id: @installed_component.application_component.app_id}} }

        it_behaves_like 'successful request', type: :json do
          it { response.body.should have_json('number.id').with_value(@installed_component.id) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@installed_component.id) }
        end
      end

      describe 'filtered by app_name' do
        let(:params) { {filters: {app_name: @installed_component.application_component.app.name}} }

        it_behaves_like 'successful request', type: :json do
          it { response.body.should have_json('number.id').with_value(@installed_component.id) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@installed_component.id) }
        end
      end

      describe 'filtered by component_id' do
        let(:params) { {filters: {component_id: @installed_component.application_component.component.id}} }

        it_behaves_like 'successful request', type: :json do
          it { response.body.should have_json('number.id').with_value(@installed_component.id) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@installed_component.id) }
        end
      end

      describe 'filtered by component_name' do
        let(:params) { {filters: {component_name: @installed_component.application_component.component.name}} }

        it_behaves_like 'successful request', type: :json do
          it { response.body.should have_json('number.id').with_value(@installed_component.id) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@installed_component.id) }
        end
      end

      describe 'filtered by environment_id' do
        let(:params) { {filters: {environment_id: @installed_component.application_environment.environment_id}} }

        it_behaves_like 'successful request', type: :json do
          it { response.body.should have_json('number.id').with_value(@installed_component.id) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@installed_component.id) }
        end
      end

      describe 'filtered by environment_name' do
        let(:params) { {filters: {environment_name: @installed_component.application_environment.environment.name}} }

        it_behaves_like 'successful request', type: :json do
          it { response.body.should have_json('number.id').with_value(@installed_component.id) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@installed_component.id) }
        end
      end

      describe 'filtered by server_group_name' do
        let(:params) { {filters: {server_group_name: @installed_component.server_group.name}} }

        it_behaves_like 'successful request', type: :json do
          it { response.body.should have_json('number.id').with_value(@installed_component.id) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { response.body.should have_xpath("#{xml_root}/id").with_text(@installed_component.id) }
        end
      end

      it_behaves_like 'entity with include_exclude support' do
        let(:excludes) { %w(application_component application_environment) }
      end
    end
  end

  describe 'GET /v1/installed_components/[id]' do
    before(:each) { @installed_component = create(:installed_component) }

    let(:url) { "#{base_url}/#{@installed_component.id}?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :json do
      subject { response.body }
      it { should have_json('number.id').with_value(@installed_component.id) }
      it { should have_json('.application_component .id').with_value(@installed_component.application_component.id) }
      it { should have_json('.application_environment .id').with_value(@installed_component.application_environment.id) }

    end

    it_behaves_like 'successful request', type: :xml do
      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(@installed_component.id) }
      it { should have_xpath("#{xml_root}/application-component/id").with_text(@installed_component.application_component.id) }
      it { should have_xpath("#{xml_root}/application-environment/id").with_text(@installed_component.application_environment.id) }
    end

    it_behaves_like 'entity with include_exclude support' do
      let(:excludes) { %w(application_component application_environment) }
    end
  end

  describe 'POST /v1/installed_components' do

    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    describe 'with names' do
      describe 'POST json' do
        before :each do
          @app = create(:app, name: 'json_app_name')
          @application_component = create(:application_component, app: @app)
          @application_environment = create(:application_environment, app: @app)
        end

        let(:component_name) { @application_component.component.name }
        let(:environment_name) { @application_environment.environment.name }
        let(:app_name) { @app.name }

        it_behaves_like 'successful request', type: :json, method: :post, status: 201 do
          let(:params) { {json_root => {app_name: app_name,
                                        component_name: component_name,
                                        environment_name: environment_name}}.to_json }
          let(:added_installed_component) { InstalledComponent.for_app_name(app_name).first }

          subject { response.body }
          it { should have_json('number.id').with_value(added_installed_component.id) }
          it { should have_json('.application_component .id').with_value(added_installed_component.application_component.id) }
          it { should have_json('.application_environment .id').with_value(added_installed_component.application_environment.id) }
        end
      end

      describe 'POST xml' do
        before :each do
          @app = create(:app, name: 'xml_app_name')
          @application_component = create(:application_component, app: @app)
          @application_environment = create(:application_environment, app: @app)
        end

        let(:component_name) { @application_component.component.name }
        let(:environment_name) { @application_environment.environment.name }
        let(:app_name) { @app.name }

        it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
          let(:params) { {app_name: app_name,
                          component_name: component_name,
                          environment_name: environment_name}.to_xml(root: xml_root) }

          let(:added_installed_component) { InstalledComponent.for_app_name(app_name).first }

          subject { response.body }
          it { should have_xpath("#{xml_root}/id").with_text(added_installed_component.id) }
          it { should have_xpath("#{xml_root}/application-component/id").with_text(added_installed_component.application_component.id) }
          it { should have_xpath("#{xml_root}/application-environment/id").with_text(added_installed_component.application_environment.id) }
        end
      end
    end

    describe 'with ids' do
      describe 'POST json' do
        before :each do
          @app = create(:app, name: 'json_app_id')
          @application_component = create(:application_component, app: @app)
          @application_environment = create(:application_environment, app: @app)
        end

        let(:application_component_id) { @application_component.id }
        let(:application_environment_id) { @application_environment.id }
        let(:app_name) { @app.name }

        it_behaves_like 'successful request', type: :json, method: :post, status: 201 do
          let(:params) { {json_root => {application_component_id: application_component_id,
                                        application_environment_id: application_environment_id}}.to_json }
          let(:added_installed_component) { InstalledComponent.for_app_name(app_name).first }

          subject { response.body }
          it { should have_json('number.id').with_value(added_installed_component.id) }
          it { should have_json('.application_component .id').with_value(added_installed_component.application_component.id) }
          it { should have_json('.application_environment .id').with_value(added_installed_component.application_environment.id) }
        end
      end

      describe 'POST xml' do
        before :each do
          @app = create(:app, name: 'xml_app_id')
          @application_component = create(:application_component, app: @app)
          @application_environment = create(:application_environment, app: @app)
        end

        let(:application_component_id) { @application_component.id }
        let(:application_environment_id) { @application_environment.id }
        let(:app_name) { @app.name }

        it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
          let(:params) { {application_component_id: application_component_id,
                          application_environment_id: application_environment_id}.to_xml(root: xml_root) }

          let(:added_installed_component) { InstalledComponent.for_app_name(app_name).first }

          subject { response.body }
          it { should have_xpath("#{xml_root}/id").with_text(added_installed_component.id) }
          it { should have_xpath("#{xml_root}/application-component/id").with_text(added_installed_component.application_component.id) }
          it { should have_xpath("#{xml_root}/application-environment/id").with_text(added_installed_component.application_environment.id) }
        end
      end
    end

    it_behaves_like 'creating request with params that fails validation' do
      let(:param) { {application_component_id: nil, application_environment_id: nil} }
    end

    it_behaves_like 'creating request with invalid params'
  end

  describe 'PUT /v1/installed_components/[id]' do
    describe 'with names' do
      before(:each) { @installed_component = create(:installed_component) }

      let(:url) { "#{base_url}/#{@installed_component.id}?token=#{@user.api_key}" }

      describe 'PUT json' do
        before :each do
          @app = create(:app, name: 'put_json_app_name')
          @application_component = create(:application_component, app: @app)
          @application_environment = create(:application_environment, app: @app)
        end

        let(:component_name) { @application_component.component.name }
        let(:environment_name) { @application_environment.environment.name }
        let(:app_name) { @app.name }

        it_behaves_like 'successful request', type: :json, method: :put, status: 202 do
          let(:params) { {json_root => {app_name: app_name,
                                        component_name: component_name,
                                        environment_name: environment_name}}.to_json }
          let(:added_installed_component) { InstalledComponent.for_app_name(app_name).first }

          subject { response.body }
          it { should have_json('number.id').with_value(added_installed_component.id) }
          it { should have_json('.application_component .id').with_value(added_installed_component.application_component.id) }
          it { should have_json('.application_environment .id').with_value(added_installed_component.application_environment.id) }
        end
      end

      describe 'PUT xml' do
        before :each do
          @app = create(:app, name: 'put_xml_app_name')
          @application_component = create(:application_component, app: @app)
          @application_environment = create(:application_environment, app: @app)
        end

        let(:component_name) { @application_component.component.name }
        let(:environment_name) { @application_environment.environment.name }
        let(:app_name) { @app.name }

        it_behaves_like 'successful request', type: :xml, method: :put, status: 202 do
          let(:params) { {app_name: app_name,
                          component_name: component_name,
                          environment_name: environment_name}.to_xml(root: xml_root) }

          let(:updated_installed_component) { InstalledComponent.for_app_name(app_name).first }

          subject { response.body }
          it { should have_xpath("#{xml_root}/id").with_text(updated_installed_component.id) }
          it { should have_xpath("#{xml_root}/application-component/id").with_text(updated_installed_component.application_component.id) }
          it { should have_xpath("#{xml_root}/application-environment/id").with_text(updated_installed_component.application_environment.id) }
        end
      end
    end

    describe 'wit ids' do
      before(:each) { @installed_component = create(:installed_component) }

      let(:url) { "#{base_url}/#{@installed_component.id}?token=#{@user.api_key}" }

      describe 'PUT json' do
        before :each do
          @app = create(:app, name: 'put_json_app_id')
          @application_component = create(:application_component, app: @app)
          @application_environment = create(:application_environment, app: @app)
        end

        let(:application_component_id) { @application_component.id }
        let(:application_environment_id) { @application_environment.id }
        let(:app_name) { @app.name }

        it_behaves_like 'successful request', type: :json, method: :put, status: 202 do
          let(:params) { {json_root => {application_component_id: application_component_id,
                                        application_environment_id: application_environment_id}}.to_json }
          let(:updated_installed_component) { InstalledComponent.for_app_name(app_name).first }

          subject { response.body }
          it { should have_json('number.id').with_value(updated_installed_component.id) }
          it { should have_json('.application_component .id').with_value(updated_installed_component.application_component.id) }
          it { should have_json('.application_environment .id').with_value(updated_installed_component.application_environment.id) }
        end
      end

      describe 'PUT xml' do
        before :each do
          @app = create(:app, name: 'put_xml_app_id')
          @application_component = create(:application_component, app: @app)
          @application_environment = create(:application_environment, app: @app)
        end

        let(:application_component_id) { @application_component.id }
        let(:application_environment_id) { @application_environment.id }
        let(:app_name) { @app.name }

        it_behaves_like 'successful request', type: :xml, method: :put, status: 202 do
          let(:params) { { application_component_id: application_component_id,
                           application_environment_id: application_environment_id}.to_xml(root: xml_root) }

          let(:updated_installed_component) { InstalledComponent.for_app_name(app_name).first }

          subject { response.body }
          it { should have_xpath("#{xml_root}/id").with_text(updated_installed_component.id) }
          it { should have_xpath("#{xml_root}/application-component/id").with_text(updated_installed_component.application_component.id) }
          it { should have_xpath("#{xml_root}/application-environment/id").with_text(updated_installed_component.application_environment.id) }
        end
      end
    end

    it_behaves_like 'editing request with params that fails validation' do
      before(:each) { @installed_component = create(:installed_component) }

      let(:url) { "#{base_url}/#{@installed_component.id}?token=#{@user.api_key}" }

      let(:param) { {application_component_id: nil, application_environment_id: nil} }
    end

    it_behaves_like 'editing request with invalid params'
  end

  # Number of defect in Rally - DE81122
  #describe 'DELETE /v1/installed_components/[id]' do
  #  tested_formats.each do |format|
  #    context 'delete installed_components' do
  #      before (:each) { @installed_component = create(:installed_component) }
  #      let(:url) { "#{base_url}/#{@installed_component.id}/?token=#{@user.api_key}" }
  #      it_behaves_like "successful request", type: format, method: :delete, status: 202 do
  #        let(:params) { { } }
  #        it { @installed_component.deactivate.should be_truthy }
  #      end
  #    end
  #  end
  #end
end
