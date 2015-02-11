require 'spec_helper'

describe '/v1/apps', import_export: true do
  before :all do
    @user = create(:user)
    create(:activity)
    create(:team, name: '[default]')
  end

  let(:base_url) { '/v1/apps' }
  let(:json_root) { :app }
  let(:xml_root) { 'app' }
  let(:import_root) { 'app_import/app' }
  let(:params) { {token: @user.api_key} }
  subject { response }

  describe 'import app_import xml with (installed) components, environments, and servers' do
    let(:app_name) { 'TestRelease' }
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      let (:xml_content) { File.open("spec/data/#{app_name}.xml", 'r').read }
      let(:added_app) { App.where(name: app_name).first }
      let(:imported_hash) { Hash.from_xml(xml_content) }
      let(:params) { xml_content }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_app.name) }

      it 'has imported components' do
        imported_components.each do |xml_component|
          component = Component.find_by_name(xml_component['name'])
          expect(component.name).to eq(xml_component['name'])
        end
      end

      it 'has imported component properties' do
        imported_components.each do |xml_component|
          if xml_component['active_properties']
            xml_component['active_properties'].each do |xml_prop|
              property = Property.find_by_name(xml_prop['name'])
              expect(property.default_value).to eq(xml_prop['default_value'])
            end
          end
        end
      end

      it 'has imported environments' do
        imported_environments.each do |xml_env|
          environment = Environment.find_by_name(xml_env['name'])
          expect(environment.name).to eq(xml_env['name'])
        end
      end

      it 'has imported servers' do
        imported_environments.each do |xml_env|
          env = Environment.find_by_name(xml_env['name'])
          if xml_env['active_environment_servers']
            xml_env['active_environment_servers'].each do |xml_server|
              if xml_server['server']
                server = Server.find_by_name(xml_server['server']['name'])
                expect(env.server_ids).to include(server.id)
              end
            end
          end
        end
      end

      it 'has imported server properties' do
        imported_servers.each do |xml_servers|
          xml_servers.each do |xml_server|
            if xml_server.is_a?(Hash) && xml_server.has_key?('server')
              server = Server.find_by_name(xml_server['server']['name'])
              expect(server.current_property_values.first.value).to eql(xml_server['server']['current_property_values'].first['value'])
            end
          end
        end
      end

      it 'has imported application components' do
        imported_installed_components.each do |xml_comp|
          comp = Component.find_by_name(xml_comp['application_component']['component']['name'])
          # app_comp = ApplicationComponent.by_application_and_component_names(added_app.name, comp.name)
          env = Environment.find_by_name(xml_comp['application_environment']['name'])
          icomp = InstalledComponent.find_by_app_comp_env(added_app, comp, env)
          expect(icomp.version).to eq(xml_comp['version'])
        end
      end
    end
  end

  describe 'import app_import xml with environment type, server groups/levels/instances' do
    let(:app_name) { 'TestRelease' }
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      let (:xml_content) { File.open("spec/data/#{app_name}.xml", 'r').read }
      let(:added_app) { App.where(name: app_name).first }
      let(:imported_hash) { Hash.from_xml(xml_content) }
      let(:params) { xml_content }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_app.name) }

      it 'has imported environment types' do
        imported_environments.each do |xml_env|
          if xml_env['environment_type']
            env_type = EnvironmentType.find_by_name(xml_env['environment_type']['name'])
            expect(env_type).not_to be_archived
          end
        end
      end

      it 'has imported server groups' do
        imported_environments.each do |xml_env|
          env = Environment.find_by_name(xml_env['name'])
          xml_env['active_server_groups'].each do |xml_server_group|
            server_group = ServerGroup.find_by_name(xml_server_group['name'])
            expect(server_group.environment_ids).to include(env.id)
          end
        end
      end

      it 'has imported server level groups' do
        imported_installed_components.each do |xml_comp|
          xml_comp['server_aspect_groups'].each do |xml_server_group|
            server_group = ServerAspectGroup.find_by_name(xml_server_group['name'])
            expect(server_group.name).to include(xml_server_group['name'])
          end
        end
      end

      it 'has imported server level groups with instance properties' do
        imported_installed_components.each do |xml_comp|
          xml_comp['server_aspect_groups'].each do |xml_server_group|
            xml_server_group['server_aspects'].each do |xml_aspect|
              if xml_aspect['current_property_values'].any?
                server_aspect = ServerAspect.find_by_name(xml_aspect['name'])
                expect(server_aspect.current_property_values.first.value).to eql(xml_aspect['current_property_values'].first['value'])
              end
            end
          end
        end
      end

      it 'has imported server levels' do
        imported_installed_components.each do |xml_icomp|
          xml_icomp['server_aspects'].each do |xml_aspect|
            if xml_aspect['server_level']
              server_level = ServerLevel.find_by_name(xml_aspect['server_level']['name'])
              expect(server_level.name).to eq(xml_aspect['server_level']['name'])
            end
          end
        end
      end

      it 'has imported server aspects' do
        imported_installed_components.each do |xml_comp|
          env = Environment.find_by_name(xml_comp['application_environment']['name'])
          xml_comp['server_aspects'].each do |xml_aspect|
            server_aspect = ServerAspect.find_by_name(xml_aspect['name'])
            expect(server_aspect.environments).to include(env)
          end
        end
      end
    end
  end

  describe 'import app_import xml with no servers' do
    app_name = 'NoServers'
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      xml_content = File.open("spec/data/#{app_name}.xml", 'r').read
      let(:added_app) { App.where(name: app_name).first }
      let(:imported_hash) { Hash.from_xml(xml_content) }
      let(:params) { xml_content }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_app.name) }

      it 'has imported server aspects' do
        imported_installed_components.each do |xml_comp|
          env = Environment.find_by_name(xml_comp['application_environment']['name'])
          xml_comp['server_aspects'].each do |xml_aspect|
            server_aspect = ServerAspect.find_by_name(xml_aspect['name'])
            if xml_aspect['parent_type'] != 'Server'
              expect(server_aspect.environments).to include(env)
            else
              expect(server_aspect).to be_falsey
            end
          end
        end
      end
    end
  end

  describe 'import app_import xml with routes' do
    app_name = 'TestRelease'
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      xml_content = File.open("spec/data/#{app_name}.xml", 'r').read
      let(:added_app) { App.where(name: app_name).first }
      let(:imported_hash) { Hash.from_xml(xml_content) }
      let(:params) { xml_content }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_app.name) }

      it 'has imported routes' do
        imported_routes.each do |xml_route|
          route = Route.where(name: xml_route['name'], app_id: added_app.id).first
          expect(route['description']).to eq(xml_route['description'])
        end
      end

      it 'has imported route gates' do
        imported_routes.each do |xml_route|
          route = Route.where(name: xml_route['name'], app_id: added_app.id).first
          xml_route['route_gates'].each do |gate|
            env = Environment.find_by_name(gate['environment']['name'])
            route_gate = RouteGate.where(route_id: route.id, environment_id: env.id).first
            expect(route_gate['position']).to eq(gate['position'])
          end
        end
      end
    end
  end

  def imported_environments
    imported_hash['app_import']['app']['environments']
  end

  def imported_components
    imported_hash['app_import']['app']['components']
  end

  def imported_installed_components
    imported_hash['app_import']['app']['installed_components']
  end

  def imported_routes
    imported_hash['app_import']['app']['active_routes']
  end

  def imported_steps
    imported_requests.flat_map do |request|
      request['steps']
    end
  end

  def imported_scripts
    imported_requests.flat_map do |request|
      request['request_template']['automation_scripts_for_export']
    end.compact
  end

  def imported_requests
    imported_hash['app_import']['app']['requests_for_export']
  end

  def imported_version_tags
    imported_hash['app_import']['app']['version_tags']
  end

  def imported_servers
    imported_environments.map do |xml_env|
      if xml_env['active_environment_servers']
        xml_env['active_environment_servers'].each do |xml_server|
          xml_server
        end
      end
    end.compact
  end

end