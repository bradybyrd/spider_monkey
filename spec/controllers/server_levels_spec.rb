require 'spec_helper'

describe ServerLevelsController, type: :controller do
  before(:each) { @server_level = create(:server_level) }

  describe 'authorization', custom_roles: true do
    context 'fails' do
      after { should redirect_to root_path }

      describe '#show' do
        include_context 'mocked abilities', :cannot, :inspect, ServerLevel
        specify { get :show, id: @server_level }
      end

      describe '#new' do
        include_context 'mocked abilities', :cannot, :create, ServerLevel
        specify { get :new }
      end

      describe '#create' do
        include_context 'mocked abilities', :cannot, :create, ServerLevel
        specify { post :create }
      end

      describe '#edit' do
        include_context 'mocked abilities', :cannot, :edit, ServerLevel
        specify { get :edit, id: @server_level }
      end

      describe '#update' do
        include_context 'mocked abilities', :cannot, :edit, ServerLevel
        specify { put :update, id: @server_level }
      end
    end
  end

  it '#new' do
    get :new
    expect(response).to render_template(partial: '_form')
  end

  context '#create' do
    it 'success' do
      expect{
        post :create, { server_level: { name: 'SL1' },
                        format: 'js' }
      }.to change(ServerLevel, :count).by(1)
      expect(flash[:success]).to include('successfully')
    end

    it 'fails' do
      ServerLevel.stub(:new).and_return(@server_level)
      @server_level.stub(:save).and_return(false)

      post :create, format: 'js'

      expect(flash[:error]).to include('problem')
    end
  end

  context '#show' do
    it "return flash 'No servers aspects'" do
      server = create(:server, active: true)
      server_aspect = create(:server_aspect,
                              server_level_id: @server_level.id,
                              parent: server)
      server_level2 = create(:server_level)
      create(:server_group, active: true)
      get :show, id: server_level2.id

      expect(assigns(:server_aspect).parent).to eq server_aspect
      expect(flash[:error]).to include('No  Instances')
    end

    it 'render partial' do
      get :show, {id: @server_level.id, render_no_rjs: true}

      expect(response).to render_template(partial: '_server_level_show')
    end

    it 'return aspects servers' do
      server = create(:server)
      servers_aspect =
          31.times.collect{ |x| create(:server_aspect,
                                        name: "Dev#{x}",
                                        server_level: @server_level,
                                        parent: server) }
      servers_aspect.sort_by!{|el| el.name}

      get :show, { id: @server_level.id, key: 'Dev' }

      sl_server_aspect = assigns(:server_level_server_aspect)
      servers_aspect[0..29].each {|el| expect(sl_server_aspect).to include(el)}
      expect(sl_server_aspect).to_not include(servers_aspect[30])
      expect(response).to render_template('show')
    end
  end

  it '#edit' do
    get :edit, { id: @server_level.id, format: 'js' }

    expect(assigns(:server_level)).to eq @server_level
    expect(response).to render_template('edit')
  end

  it '#update' do
    put :update, { id: @server_level.id,
                   server_level: { name: 'SLch' },
                   format: 'js'}
    @server_level.reload
    expect(@server_level.name).to eq 'SLch'
    expect(response).to be_success
  end

  context '#search' do
    specify 'with keyword' do
      pending "undefined method `server_level_id_equals'"
      server = create(:server)
      server_aspect = create(:server_aspect,
                              server_level: @server_level, parent: server, name: 'Dev1')

      get :search, { id: @server_level.id, key: 'Dev' }

      expect(response).to render_template('show')
      expect(assigns(:server_level_server_aspect)).to include(server_aspect)
    end

    specify 'without keyword' do
      get :search, id: @server_level.id
      expect(response).to redirect_to(server_level_path(@server_level.id))
    end
  end
end
