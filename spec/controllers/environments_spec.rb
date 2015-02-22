require 'spec_helper'

describe EnvironmentsController, type: :controller do
  before(:each) { @env = create(:environment, active: true) }

  #### common values
  model = Environment
  factory_model = :environment
  can_archive = false
  #### values for index
  models_name = 'environments'
  model_index_path = '_index'
  be_sort = true
  per_page = 30
  index_flash = 'No Environment'
  #### values for edit
  model_edit_path = '/index'
  edit_flash = 'Environment was not found'
  http_refer = true
  #### values for create
  model_create_path = nil
  create_params =  {environment: {name: 'name_changed'}}
  #### values for update
  update_params = {name: 'name_ch'}
  #### values for destroy
  model_delete_path = '/environment/environments'

  it_should_behave_like('CRUD GET index', model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like('CRUD GET new')
  it_should_behave_like('CRUD GET edit', factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like('CRUD POST create', model, factory_model, model_create_path, create_params)
  it_should_behave_like('CRUD PUT update', model, factory_model, update_params)
  it_should_behave_like('CRUD DELETE destroy', model, factory_model, model_delete_path, can_archive)

  it '#update_server_selects' do
    server = create(:server)
    server_group = create(:server_group)
    params  = {default_server_id: server.id,
                format: 'js',
                environment: {default_server_group_id: server_group.id,
                              server_group_ids: [server_group.id],
                              server_ids: [server.id]}}
    get :update_server_selects, params

    expect(response.code).to eq '200'
    expect(assigns(:selected_default_server_id)).to eq server.id
    expect(assigns(:selected_default_server_group_id)).to eq server_group.id
  end

  it '#create_default' do
    post :create_default
    expect(response).to redirect_to(environments_path)
  end

  it '#environments_of_app' do
    app = create(:app)
    get :environments_of_app, app_id: app.id, format: 'js'
    expect(response.code).to eq '200'
    expect(assigns(:app)).to eq app
  end

  context '#update server association' do
    before(:each) do
      @server = create(:server, active: true )
      @environment = create(:environment, servers: [@server] )
      @app = create(:app, environments: [@environment])
    end

    it 'should allow removal from environments without package reference to server' do
      put :update, id: @environment.id, environment: { server_ids: [] }

      @environment.reload
      expect(@environment.server_ids). to eql([ ])
    end

    it 'should prevent removal from environments with package reference to server' do
      package = create(:package)
      create(:reference, package: package, server: @server)
      @app.packages << package

      put :update, id: @environment.id, environment: { server_ids: [] }

      @environment.reload
      expect(@environment.server_ids).to eql([ @server.id ])
    end
  end

end
