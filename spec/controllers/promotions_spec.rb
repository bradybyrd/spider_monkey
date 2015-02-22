require 'spec_helper'

describe PromotionsController, type: :controller do
  before(:each) do
    request = create(:request_with_app)
    @app = request.apps.first
    component = create(:component)
    @environment = request.environment
    app_environment = ApplicationEnvironment.by_application_and_environment_names(@app.name, @environment.name).first
    app_component = create(:application_component, app: @app, component: component)
    create(:project_server)
    create(:installed_component,
            application_environment: app_environment,
            application_component: app_component)
    @request_template = create(:request_template, request: request)
  end

  it '#new' do
    get :new, app_id: @app.id

    expect(assigns(:request_templates)).to include(@request_template)
    expect(response).to render_template('new')
  end

  context '#promotion_table' do
    it 'creates promotion' do
      post :promotion_table, { format: 'js',
                               promotion: { app_id: @app,
                                            target_env: @environment,
                                            source_env: @environment}}
      expect(assigns(:app)).to eq @app
      expect(response).to render_template('promotion_table')
    end

    it 'returns validation errors' do
      post :promotion_table, { promotion: { app_id: @app }}

      expect(response).to render_template('misc/error_messages_for')
    end
  end
end