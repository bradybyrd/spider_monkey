require 'spec_helper'

describe ServerGroupsController, type: :controller do
  render_views

  before(:each) { @server_group = create(:server_group) }

  #### common values
  model = ServerGroup
  factory_model = :server_group
  can_archive = false
  #### values for destroy
  model_delete_path = '/environment/servers'

  it_should_behave_like('CRUD GET new')
  it_should_behave_like('CRUD DELETE destroy', model, factory_model, model_delete_path, can_archive)

  describe 'authorization', custom_roles: true do
    context 'fails' do
      after { should redirect_to root_path }

      describe '#index' do
        include_context 'mocked abilities', :cannot, :list, ServerGroup
        specify { get :index }
      end

      describe '#new' do
        include_context 'mocked abilities', :cannot, :create, ServerGroup
        specify { get :new }
      end

      describe '#create' do
        include_context 'mocked abilities', :cannot, :create, ServerGroup
        specify { post :create }
      end

      describe '#edit' do
        include_context 'mocked abilities', :cannot, :edit, ServerGroup
        specify { get :edit, id: @server_group }
      end

      describe '#update' do
        include_context 'mocked abilities', :cannot, :edit, ServerGroup
        specify { put :update, id: @server_group }
      end

      describe '#activate' do
        include_context 'mocked abilities', :cannot, :make_active_inactive, ServerGroup
        specify { put :activate, id: @server_group }
      end

      describe '#deactivate' do
        include_context 'mocked abilities', :cannot, :make_active_inactive, ServerGroup
        specify { put :activate, id: @server_group }
      end

      describe '#destroy' do
        include_context 'mocked abilities', :cannot, :delete, ServerGroup
        specify { delete :destroy, id: @server_group }
      end
    end
  end

  context '#index' do
    it "return flash 'No Server groups'" do
      ServerGroup.delete_all

      get :index

      expect(flash[:error]).to include('No Server Group')
      expect(response).to be_truthy
    end

    it '#index render partial' do
      get :index, render_no_rjs: true
      expect(response).to render_template(partial: '_index')
    end

    context 'find' do
      it 'with keyword' do
        server_group1 = create(:server_group, name: 'Dev1', active: true)
        server_group2 = create(:server_group, name: 'Dev2', active: false)

        get :index, key: 'Dev'

        expect(assigns(:active_server_groups)).to include(server_group1)
        expect(assigns(:active_server_groups)).to_not include(@server_group)
        expect(assigns(:inactive_server_groups)).to include(server_group2)
        expect(assigns(:inactive_server_groups)).to_not include(@server_group)
      end

      it 'without keyword' do
        inactive_server_groups = 20.times.collect{create(:server_group, active: false)}

        get :index, page: 1

        expect(assigns(:active_server_groups)).to include(@server_group)
        inactive_server_groups[0..20].each{|el| expect(assigns(:active_server_groups)).to_not include(el)}
        inactive_server_groups[0..20].each{|el| expect(assigns(:inactive_server_groups)).to include(el)}
        expect(assigns(:inactive_server_groups)).to_not include(@server_group)
      end
    end
  end


  it '#activate' do
    server_group = create(:server_group, active: false)

    put :activate, { id: server_group.id, format: 'js' }

    expect(ServerGroup.find(server_group.id).active).to be_truthy
    expect(response).to render_template('misc/redirect')
  end

  it '#deactivate' do
    server_group = create(:server_group, active: true)

    put :deactivate, { id: server_group.id, format: 'js' }

    expect(ServerGroup.find(server_group.id).active).to be_falsey
    expect(response).to render_template('misc/redirect')
  end

  describe '#create' do
    it 'success' do
      post :create, { server_group: { name: 'SG1' }}

      expect(flash[:success]).to include('successfully')
      expect(response).to redirect_to(servers_path)
    end

    it 'fails' do
      server_gr = ServerGroup.new
      ServerGroup.stub(:new).and_return(server_gr)

      post :create

      expect(flash[:error]).to include('was a problem')
      expect(response).to render_template('new')
    end

    it 'xhr success' do
      xhr :post, :create, { server_group: { name: 'SG1' }}
      expect(response).to render_template('index')
    end

    it 'xhr fails' do
      server_gr = ServerGroup.new
      ServerGroup.stub(:new).and_return(server_gr)

      xhr :post, :create

      expect(response.body).to include('error_messages')
    end
  end

  context '#edit' do
    it 'get' do
      get :edit, { id: @server_group.id, format: 'js' }

      expect(response).to render_template('edit')
    end

    it 'xhr' do
      xhr :get, :edit, { id: @server_group.id, format: 'js' }

      expect(response).to render_template('server_groups/load_form')
    end
  end

  describe '#update' do
    it 'success' do
      put :update, { id: @server_group.id,
                     server_group: { name: 'SG_changed' }}

      expect(flash[:success]).to include('successfully')
      @server_group.reload
      expect(@server_group.name).to eq 'SG_changed'
      expect(response).to redirect_to servers_path
    end

    it 'fails' do
      server_gr = ServerGroup.new
      ServerGroup.stub(:find).and_return(server_gr)

      put :update, { id: @server_group.id,
                     server_group: {} }

      expect(flash[:error]).to include('was a problem')
      expect(response).to render_template('edit')
    end

    it 'success xhr' do
      xhr :put, :update, { id: @server_group.id,
                           server_group: { name: 'SG_changed2' }}
      @server_group.reload
      expect(@server_group.name).to eq 'SG_changed2'
      expect(response).to render_template('index')
    end

    it 'invalid xhr' do
      server_gr = ServerGroup.new
      ServerGroup.stub(:find).and_return(server_gr)

      xhr :put, :update, { id: @server_group.id,
                           server_group: {} }

      expect(response.body).to include('error_messages')
    end
  end
end
