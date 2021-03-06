require 'spec_helper'

describe MapsController, type: :controller do
  before(:each) do
    @app = create(:app)
    @env = create(:environment)
    @app_env = create(:application_environment, :app => @app,
                                                :environment => @env)
    @component = create(:component)
    @app_component = create(:application_component, :app => @app,
                                                    :component => @component)
    @installed_component = create(:installed_component, :application_environment => @app_env,
                                                        :application_component => @app_component)
    @property = create(:property)
    @app.properties << @property
    @component.properties << @property
    @server = create(:server)
    @server_level = create(:server_level)
    @server_aspect = create(:server_aspect, :server_level_id => @server_level.id,
                                            :parent => @server)
    @aspect_group = create(:server_aspect_group)
    @server_aspect.groups << @aspect_group
    @env.servers << @server
    @installed_component.server_aspects << @server_aspect
  end

  describe 'authorization', custom_roles: true do
    context 'authorization fails' do
      after { should redirect_to root_path }

      describe '#index' do
        include_context 'mocked abilities', :cannot, :view, :maps_reports
        specify { get :index }
      end

      describe '#versions_by_app' do
        include_context 'mocked abilities', :cannot, :view, :component_versions_map
        specify { get :versions_by_app }
      end

      describe '#properties' do
        include_context 'mocked abilities', :cannot, :view, :properties_map
        specify { get :properties }
      end

      describe '#servers_by_app' do
        include_context 'mocked abilities', :cannot, :view, :servers_map_by_app
        specify { get :servers_by_app }
      end

      describe '#servers' do
        include_context 'mocked abilities', :cannot, :view, :server_map
        specify { get :servers }
      end

      describe '#application_component_summary' do
        include_context 'mocked abilities', :cannot, :view, :app_component_summary_map
        specify { get :application_component_summary }
      end
    end
  end

  it '#index' do
    get :index

    expect(response).to render_template('index')
  end

  it '#versions_by_app' do
    post :versions_by_app, { app_id: @app.id,
                             application_environment_ids: [@app_env.id] }

    expect(assigns(:selected_application_environments)).to include(@app_env)
    expect(response).to render_template('versions_by_app')
  end

  it '#components_by_environment' do
    post :components_by_environment, { environment_ids: [@env.id] }

    expect(assigns(:environments)).to include(@env)
    expect(response).to render_template('components_by_environment')
  end

  it '#servers' do
    get :servers, { environment_ids: [@env.id],
                    server_ids: [@server.id],
                    server_level_ids: [@server_level.id] }

    expect(assigns(:environment_for_select)).to include(@env)
    expect(assigns(:servers)).to include(@server)
    expect(assigns(:server_level_ids)).to include(@server_level.id)
    expect(response).to render_template('servers')
  end

  it '#servers_by_app' do
    get :servers_by_app

    expect(response).to render_template('servers_by_app')
  end

  it '#servers_by_environment' do
    get :servers_by_environment

    expect(assigns(:environments)).to include(@env)
    expect(response).to render_template('servers_by_environment')
  end

  it '#logical_servers' do
    get :logical_servers

    levels = { @env => { @server_level => [@server] }}
    expect(assigns(:levels_by_environment)).to eq levels
    expect(response).to render_template('logical_servers')
  end

  it '#properties' do
    release = create(:release)

    post :properties, { app_id: @app.id,
                        application_environment_ids: [@app_env.id],
                        component_ids: [@component.id],
                        release_ids: [release.id]}

    expect(assigns(:selected_application_environments)).to include(@app_env)
    expect(assigns(:selected_components)).to include(@component)
    expect(assigns(:releases)).to include(release)
    expect(response).to render_template('properties')
  end

  it '#application_component_summary' do
    xhr :get, :application_component_summary, { app_ids: [@app.id],
                                                application_environment_ids: [@app_env.id],
                                                component_ids: [@component.id]}

    expect(response).to render_template(partial: 'maps/_application_component_summary')
  end

  it '#environments' do
    post :environments, { app_ids: [@app.id],
                          environment_ids: [@env.id],
                          server_level_ids: [@server_level.id]}
    expect(response).to render_template('environments')
  end

  context '#multiple_application_environment_options' do
    it 'renders options' do
      get :multiple_application_environment_options, { app_ids: [@app.id] }

      expect(response.body).to include("#{@app.name}")
    end

    it 'returns nothing' do
      get :multiple_application_environment_options, {app_ids: []}

      expect(response.body).to eq ' '
    end
  end

  context '#component_options' do
    specify 'string params' do
      get :component_options, { app_ids: [@app.id],
                                application_environment_ids: ["#{@env.id}_", @app_env.id]}

      expect(response.body).to include("#{@component.name}")
    end

    specify 'array params' do
      get :component_options, { app_ids: [@app.id],
                                application_environment_ids: [@app_env.id]}

      expect(response.body).to include("#{@component.name}")
    end
  end

  it '#property_options' do
    get :property_options, { app_ids: [@app.id] }

    expect(response.body).to include("#{@property.name}")
  end

  it '#server_aspect_group_options' do
    get :server_aspect_group_options, { app_ids: [@app.id] }

    expect(response.body).to include("#{@aspect_group.name}")
  end

  it '#application_environment_and_component_options_for_app' do
    get :application_environment_and_component_options_for_app,
        { app_id: @app.id,
          selected_application_environment_ids: [@app_env.id],
          format: 'js' }

    expect(assigns(:component_options)).to include("#{@component.name}")
    expect(response).to render_template('application_environment_and_component_options_for_app')
  end

  it '#application_environment_options_for_app' do
    get :application_environment_options_for_app, { app_id: @app.id }

    expect(response.body).to include("#{@app_env.name}")
  end

  it '#component_options_for_app' do
    get :component_options_for_app, { app_id: @app.id }

    expect(response.body).to include("#{@component.name}")
  end

  it '#server_options_for_environment' do
    get :server_options_for_environment, { environment_id: @env.id }

    expect(response.body).to include("#{@server.name}")
  end

  context '#property_value_history' do
    specify 'with property for date' do
      get :property_value_history, { application_environment_id: @app_env.id,
                                     component_ids: [@component.id],
                                     custom_value_change_date: Time.now }
      expect(response.body).to include("#{@property.id}")
    end

    specify 'without property for date' do
      #TODO field_value must be nil
      get :property_value_history, { application_environment_id: @app_env.id,
                                     component_ids: [@component.id],
                                     custom_value_change_date: Time.now }

      expect(response.body).to include("#{@app_env.id}")
    end
  end
end
