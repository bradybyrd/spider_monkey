require 'spec_helper'

describe ProjectServersController, type: :controller do
  #### common values
  model = ProjectServer
  factory_model = :project_server
  #### values for edit
  model_edit_path = '/project_servers'
  edit_flash = nil
  http_refer = nil
  #### values for create
  model_create_path = nil
  create_params =  { project_server: { name: 'name_changed',
                                       server_name_id: '5',
                                       server_url: 'http://137.72.224.176:8080',
                                       username:  'ss',
                                       password: '' }}
  #### values for update
  update_params = { name: 'name_ch' }

  it_should_behave_like('CRUD GET new')
  it_should_behave_like('CRUD GET edit', factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like('CRUD PUT update', model, factory_model, update_params)
  it_should_behave_like('CRUD POST create', model, factory_model, model_create_path, create_params)

  before(:each) { @project_server = create(:project_server) }

  describe 'authorization', custom_roles: true do
    context 'fails' do
      describe '#index' do
        include_context 'mocked abilities', :cannot, :list, ProjectServer

        it 'redirects to root path' do
          get :index
          is_expected.to redirect_to root_path
        end
      end
    end
  end

  context '#index' do
    it 'renders partial with xhr request' do
      xhr :get, :index

      expect(response).to render_template(partial: '_index')
    end

    it 'returns flash no elements' do
      ProjectServer.delete_all
      get :index
      expect(flash[:error]).to include('No Project Server')
    end

    context 'returns valid data' do
      before(:each) do
        ProjectServer.delete_all
      end

      it 'with pagination and renders template' do
        shown_models = create_list :project_server, 30
        hidden_models = create_pair :project_server

        get :index

        expect(assigns(:active_project_servers)).to eq shown_models
        expect(assigns(:active_project_servers)).to_not include(*hidden_models)
        expect(response).to render_template('index')
      end

      it 'with keyword' do
        active_dev_model = create(:project_server, name: 'dev_active', is_active: true)
        inactive_dev_model = create(:project_server, name: 'dev_inactive', is_active: false)
        active_other_model = create(:project_server, name: 'other_active', is_active: true)
        inactive_other_model = create(:project_server, name: 'other_inactive', is_active: false)

        get :index, key: 'dev'

        active_models = assigns(:active_project_servers)
        inactive_models = assigns(:inactive_project_servers)
        expect(active_models).to include(active_dev_model)
        expect(active_models).to_not include(active_other_model)
        expect(inactive_models).to include(inactive_dev_model)
        expect(inactive_models).to_not include(inactive_other_model)
      end
    end
  end

  it '#activate' do
    @project_server.deactivate!

    put :activate, id: @project_server.id

    expect(response).to redirect_to(project_servers_url)
    @project_server.reload
    expect(@project_server.is_active).to be_truthy
  end

  it '#deactivate' do
    @project_server.activate!

    put :deactivate, id: @project_server.id

    expect(response).to redirect_to(project_servers_url)
    @project_server.reload
    expect(@project_server.is_active).to_not be_truthy
  end

  it '#build_parameters' do
    post :build_parameters, { id: @project_server.id,
                              script_content: 'new script content'}

    expect(response).to render_template(text: 'new script content', layout: false)
  end
end
