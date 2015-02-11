require "spec_helper"

describe ServersController, :type => :controller do
  #### common values
  model = Server
  factory_model = :server
  can_archive = false
  #### values for index
  models_name = 'servers'
  model_index_path = '_list'
  be_sort = true
  per_page = 30
  index_flash = "No Servers"
  #### values for edit
  model_edit_path = '/environment/servers'
  edit_flash = nil
  http_refer = nil
  #### values for create
  model_create_path = nil
  create_params =  {:server => {:name => 'server_name'}}
  #### values for update
  update_params = {:name => 'name_ch'}
  #### values for destroy
  model_delete_path = '/environment/servers?page=0'

  it_should_behave_like("CRUD GET index", model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like("CRUD GET new")
  it_should_behave_like("CRUD GET edit", factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like("CRUD POST create", model, factory_model, model_create_path, create_params)
  # it_should_behave_like("CRUD DELETE destroy", model, factory_model, model_delete_path, can_archive)

  describe 'authorization', custom_roles: true do
    context 'shows validation' do
      describe '#update' do
        include_context 'mocked abilities', :cannot, :edit, Server

        context '#update_name' do
          it 'shows validation error' do
            User.any_instance.stub(:cannot?).and_return(true)
            put :update, id: create(:server), name_update: true, server: { name: 'new name' }
            expect(assigns(:server).errors.full_messages).to include I18n.t('permissions.action_not_permitted', action: 'edit', subject: 'Server')
            expect(response.status).to eq 200
          end
        end

        context '#update_all' do
          it 'shows validation error' do
            User.any_instance.stub(:cannot?).and_return(true)
            put :update, id: create(:server), server: { name: 'new name' }
            expect(assigns(:server).errors.full_messages).to include I18n.t('permissions.action_not_permitted', action: 'edit', subject: 'Server')
            expect(response.status).to eq 200
          end
        end
      end

      describe '#create' do
        include_context 'mocked abilities', :cannot, :create, Server

        it 'shows validation error' do
          User.any_instance.stub(:cannot?).and_return(true)
          post :create
          expect(assigns(:server).errors.full_messages).to include I18n.t('permissions.action_not_permitted', action: 'create', subject: 'Server')
          expect(response.status).to eq 200
        end
      end
    end

    context 'fails' do
      after { should redirect_to root_path }

      describe '#index' do
        include_context 'mocked abilities', :cannot, :view, :environment_tab
        specify { get :index }
      end

      describe '#new' do
        include_context 'mocked abilities', :cannot, :create, Server
        specify { get :new }
      end

      describe '#edit' do
        include_context 'mocked abilities', :cannot, :edit, Server
        specify { get :edit, id: create(:server) }
      end

      describe '#activate' do
        include_context 'mocked abilities', :cannot, :make_active_inactive, Server
        specify { put :activate, id: create(:server) }
      end

      describe '#deactivate' do
        include_context 'mocked abilities', :cannot, :make_active_inactive, Server
        specify { put :activate, id: create(:server) }
      end

      describe '#destroy' do
        include_context 'mocked abilities', :cannot, :delete, Server
        specify { delete :destroy, id: create(:server) }
      end
    end
  end

  describe "DELETE destroy" do
    let!(:server) { create(:server) }

    before do
      Server.any_instance.stub(:destroyable?).and_return(true)
    end

    it 'deletes server' do
      expect { delete :destroy, id: server }.to change(Server, :count).by(-1)
    end

    it 'redirects to servers_path' do
      delete :destroy, id: server
      response.should redirect_to(model_delete_path)
    end
  end

  context "#update" do
    before(:each) do
      @server = create(:server, :active => true)
      @server_group = create(:server_group)
      @environment = create(:environment)
    end

    it "changes attributes" do
      put :update, id: @server.id, server: { name: 'new name' }
      assigns(:server).name.should eq 'new name'
      flash[:notice].should include('successfully')
      response.code.should eql('302')
    end

    it "fails changing attributes" do
      put :update, id: @server.id, server: { :name => '' }
      should render_template('edit')
    end

    it "changes all attributes" do
      put :update, {:id => @server.id,
                    :server => {:environment_ids => @environment.id,
                                :server_group_ids => @server_group},
                    :name_update => nil}
      flash[:notice].should include('successfully updated')
      @server.reload
      @server.environment_ids.should include(@environment.id)
      @server.server_group_ids.should include(@server_group.id)
      response.should redirect_to(servers_path)
    end

    it "updates name" do
      put :update, {:id => @server.id,
                    :name_update => true,
                    :server => {:name => 'Server_changed2'}}
      @server.reload
      @server.name.should eql('Server_changed2')
      response.should redirect_to(edit_server_path(:page => 0))
    end

    it "doesn`t update attributes" do
      Server.any_instance.stub(:update_attributes).and_return(false)
      put :update, { id: @server.id,
                     name_update: nil,
                     server: { environment_ids: @environment.id } }
      @server.reload
      @server.environment_ids.should_not include(@environment.id)
      response.should render_template('edit')
    end

    it "environments and server_groups by blank arrays" do
      put :update, {:id => @server.id,
                    :name_update => nil}
      @server.reload
      @server.environment_ids.should eql([])
      @server.server_group_ids.should eql([])
    end


    context "server environment associations" do
      before (:each ){
        @app = create(:app, environments:[@environment])

        @server.environments << @environment
        @server.reload
      }

      it "should allow removal from environments without package reference to server" do
        put :update, id: @server.id, server: { name: 'new name', environment_ids: [] }
        @server.reload
        expect(@server.environment_ids).to eql([ ])
      end

      it "should prevent removal from environments with package reference to server" do
        package = create( :package )
        reference = create( :reference, package: package, server: @server )
        @app.packages << package

        put :update, id: @server.id, server: { name: 'new name', environment_ids: [] }

        @server.reload
        expect(@server.environment_ids).to eql([ @environment.id ])
        end
      end

  end
end
