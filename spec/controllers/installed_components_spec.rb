require 'spec_helper'

describe InstalledComponentsController, :type => :controller do
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
    @app_component1 = create(:application_component, :app => @app,
                                                     :component => @component)
  end

  context 'authorization' do
    context 'authorize fails' do
      after { expect(response).to redirect_to root_path }

      context '#create' do
        include_context 'mocked abilities', :cannot, :create, InstalledComponent
        specify { post :create, app_id: @app.id }
      end

      context '#edit' do
        include_context 'mocked abilities', :cannot, :manage_servers, InstalledComponent
        specify { get :edit, app_id: @app.id, id: @installed_component.id }
      end

      context '#update' do
        include_context 'mocked abilities', :cannot, :manage_servers, InstalledComponent
        specify { put :update, app_id: @app.id, id: @installed_component.id }
      end

      context '#destroy' do
        include_context 'mocked abilities', :cannot, :destroy, InstalledComponent
        specify { delete :destroy, app_id: @app.id, id: @installed_component.id }
      end

      context '#add_remove_servers' do
        include_context 'mocked abilities', :cannot, :manage_servers, InstalledComponent
        specify { delete :add_remove_servers, application_environment_id: @app_env.id  }
      end

      context '#update_servers' do
        include_context 'mocked abilities', :cannot, :manage_servers, InstalledComponent
        specify { post :update_servers }
      end
    end
  end

  context "#create" do
      it "success" do
        expect{post :create, {:app_id => @app.id,
                              :installed_component => {:application_component_id => @app_component1.id,
                                                       :application_environment_id => @app_env.id}}
              }.to change(InstalledComponent, :count).by(1)
      end

      it "fails" do
        expect{post :create, {:app_id => @app.id,
                              :installed_component => {:application_component_id => @app_component.id,
                                                       :application_environment_id => @app_env.id}}
              }.to change(InstalledComponent, :count).by(0)
      end
  end

  context "#edit" do
    specify "without servers" do
      get :edit, {:id => @installed_component.id,
                  :app_id => @app.id}
      response.should render_template(:layout => false)
    end

    specify "with servers" do
      @server = create(:server)
      @env.servers << @server
      get :edit, {:id => @installed_component.id,
                  :app_id => @app.id}
      response.should render_template(:layout => false)
    end
  end

  context "#update" do
    before(:each) do
      @server = create(:server)
      @server_group = create(:server_group)
      @server_aspect = create(:server_aspect)
      @server_aspect_group = create(:server_aspect_group)
      @params = {:id => @installed_component.id,
                 :app_id => @app.id,
                 :server_association_type => 'server',
                 :installed_component => {:default_server_group_id => @server_group.id,
                                          :server_aspect_ids => [@server_aspect.id],
                                          :server_aspect_group_ids => [@server_aspect_group.id],
                                          :server_ids => [@server.id]},
                 :save_anyway => true,
                 :format => 'js'}
    end

    it "changes attribute servers" do
      put :update, @params
      @installed_component.reload
      @installed_component.server_ids.should include(@server.id)
    end

    it "changes attribute default_server_group" do
      @params[:server_association_type] = 'server_group'
      put :update, @params
      @installed_component.reload
      @installed_component.default_server_group_id.should eql(@server_group.id)
    end

    it "changes attribute server_aspect_groups" do
      @params[:server_association_type] = 'server_aspect_group'
      put :update, @params
      @installed_component.reload
      @installed_component.server_aspect_group_ids.should include(@server_aspect_group.id)
    end

    it "changes attribute server_aspects" do
      @params[:server_association_type] = nil
      put :update, @params
      @installed_component.reload
      @installed_component.server_aspect_ids.should include(@server_aspect.id)
    end

    it "changes property_value" do
      @property = create(:property)
      put :update, {:id => @installed_component.id,
                    :app_id => @app.id,
                    :installed_component => {:default_server_group_id => @server_group.id,
                                             :server_aspect_ids => [@server_aspect.id],
                                             :server_aspect_group_ids => [@server_aspect_group.id],
                                             :server_ids => [@server.id]},
                    :property_values => [[@property.id, "changed_value"]],
                    :format => 'js'}
      @property.reload
      #TODO refactor next line
      @property.current_property_values.where("value_holder_type"=> "InstalledComponent").first.value.should eql("changed_value")
    end
  end

  it "#destroy" do
    expect{delete :destroy, {:id => @installed_component.id,
                             :app_id => @app.id}
          }.to change(InstalledComponent, :count).by(-1)
  end

  context "#add_remove_servers" do
    it "returns associated servers" do
      @server = create(:server)
      @server2 = create(:server)
      @env.servers << @server2
      @env.servers << @server
      get :add_remove_servers, {:application_environment_id => @app_env.id}
      response.should render_template(:layout => false)
      assigns(:available_server_associations).first.first.first.should eql(@server)
      assigns(:available_server_associations).first.first.last.should eql(@server2)
    end

    it "returns no servers" do
      get :add_remove_servers, {:application_environment_id => @app_env.id}
      response.should render_template(:layout => false)
      assigns(:available_server_associations).should eql({})
    end
  end

  it "#update_servers" do
    @server1 = create(:server)
    @server2 = create(:server)
    @server_level = create(:server_level)
    @installed_component.server_ids << @server1.id
    put :update_servers, {:installed_component_ids => [@installed_component.id],
                          :server_ids_to_add => [@server2.id],
                          :server_ids_to_remove => [@server1.id]}
    response.body.should include("#{@server2.name}")
    response.body.should_not include("#{@server1.name}")
  end
end
