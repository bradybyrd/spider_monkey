require "spec_helper"

describe ServerAspectsController, :type => :controller do
  render_views

  before(:each) do
    @server = create(:server)
    @server_level = create(:server_level)
    @server_aspect = create(:server_aspect,
                            :server_level_id => @server_level.id,
                            :parent => @server)
  end

  describe 'authorization', custom_roles: true do
    context 'fails' do
      after { should redirect_to root_path }

      describe '#new' do
        include_context 'mocked abilities', :cannot, :add, ServerAspect
        specify { get :new, server_level_id: @server_level }
      end

      describe '#create' do
        include_context 'mocked abilities', :cannot, :add, ServerAspect
        specify { post :create, server_level_id: @server_level }
      end

      describe '#edit' do
        include_context 'mocked abilities', :cannot, :edit, ServerAspect
        specify { get :edit, id: @server_aspect, server_level_id: @server_level }
      end

      describe '#update' do
        include_context 'mocked abilities', :cannot, :edit, ServerAspect
        specify { put :update, id: @server_aspect, server_level_id: @server_level, server_aspect: { :name => 'changed' } }
      end

      describe '#destroy' do
        include_context 'mocked abilities', :cannot, :delete, ServerAspect
        specify { delete :destroy, id: @server_aspect, server_level_id: @server_level }
      end

      describe '#edit_property_values' do
        include_context 'mocked abilities', :cannot, :edit_property, ServerAspect
        specify { get :edit_property_values, id: @server_aspect, server_level_id: @server_level }
      end

      describe '#update_property_values' do
        include_context 'mocked abilities', :cannot, :edit_property, ServerAspect
        specify { put :update_property_values, id: @server_aspect, server_level_id: @server_level }
      end
    end
  end

  it "#new" do
    @server_level = create(:server_level)
    @server_aspect2 = create(:server_aspect,
                            :server_level_id => @server_level.id,
                            :parent => @server_aspect)
    get :new, {:server_level_id => @server_level.id,
               :format => 'js'}
    assigns(:server_aspect).parent.should eql(@server_aspect)
    response.should render_template('server_aspects/load_form')
  end

  context "#create" do
    it "render save" do
      post :create, {:server_level_id => @server_level.id,
                     :format => 'js',
                     :server_aspect => {:name => 'SerAsp1'}}
      response.should render_template('server_aspects/save')
    end

    it "render update" do
      @parent = create(:server_aspect)
      xhr :post, :create, {:server_level_id => @server_level.id,
                           :format => 'js',
                           :server_aspect => {:name => 'SerAsp1',
                                              :parent => @parent}}
      response.should render_template('server_aspects/update')
    end
  end

  it "#edit" do
    get :edit, {:server_level_id => @server_level.id,
                :id => @server_aspect.id,
                :format => 'js'}
    response.should render_template('server_aspects/load_form')
  end

  context "#update" do
    it "render save" do
      put :update, {:server_level_id => @server_level.id,
                    :id => @server_aspect.id,
                    :format => 'js',
                    :server_aspect => {:name => 'SerAsp_changed'}}
      @server_aspect.reload
      @server_aspect.name.should eql('SerAsp_changed')
      response.should render_template('server_aspects/save')
    end

    it "render update" do
      xhr :put, :update, {:server_level_id => @server_level.id,
                          :id => @server_aspect.id,
                          :format => 'js',
                          :server_aspect => {:name => 'SerAsp_changed2'}}
      @server_aspect.reload
      @server_aspect.name.should eql('SerAsp_changed2')
      response.should render_template('server_aspects/update')
    end
  end

  context "#destroy" do
    it "success" do
      expect{ xhr :delete, :destroy, { :server_level_id => @server_level.id,
                                       :id => @server_aspect.id
                                     }
            }.to change(ServerAspect, :count).by(-1)
    end

    it "fails" do
      ServerAspect.any_instance.stub(:destroy).and_return(false)

      expect{ xhr :delete, :destroy, { :server_level_id => @server_level.id,
                                       :id => @server_aspect.id
                                     }
            }.to change(ServerAspect, :count).by(0)

      expect(flash[:error]).to eq I18n.t('server_aspect.delete_error')
    end
  end

  it "#edit_property_values" do
    put :edit_property_values, {:server_level_id => @server_level.id,
                                :id => @server_aspect.id,
                                :format => 'js'}
    response.should render_template('edit_property_values')
  end

  it "#update_property_values" do
    @property = @server_aspect.properties.create(:name => 'prop1')
    put :update_property_values, {:server_level_id => @server_level.id,
                                  :id => @server_aspect.id,
                                  :property_values => [[@property.id, "val"]],
                                  :format => 'js'}
    response.should render_template('server_aspects/_form')
  end

  it "#expand_tree" do
    get :expand_tree, {:server_level_id => @server_level.id,
                       :id => @server_aspect.id,
                       :format => 'js'}
    assigns(:server_aspect).should eql(@server_aspect)
  end

  it "#collapse_tree" do
    get :collapse_tree, {:server_level_id => @server_level.id,
                         :id => @server_aspect.id,
                         :format => 'js'}
    assigns(:server_aspect).should eql(@server_aspect)
  end

  it "#environment_options" do
    @env = create(:environment)
    create(:environment_server, :server => @server, :environment => @env, :server_aspect => nil)
    @server.environment_ids = [@env.id]
    get :environment_options, {:server_level_id => @server_level.id,
                               :id => @server_aspect.id,
                               :server_aspect => {:parent_type_and_id => "Server::#{@server.id}"}}
    response.body.should include("#{@env.name}")
  end

  context "#update_environmentsList" do
    before(:each) do
      @env = create(:environment)
      @params = {:server_level_id => @server_level.id,
                 :id => @server_aspect.id,
                 :format => 'js'}
    end

    specify "Server" do
      @server = create(:server)
      @server.environments << @env
      @params[:server_aspect_parent_type_and_id] = "Server::#{@server.id}"
      get :update_environmentsList, @params
      assigns(:available_environments).should include(@env)
      response.should render_template(:partial => 'shared/_checkbox_select_list')
    end

    specify "ServerAspect" do
      @server_aspect.environments << @env
      @params[:server_aspect_parent_type_and_id] = "ServerAspect::#{@server_aspect.id}"
      get :update_environmentsList, @params
      assigns(:available_environments).should include(@env)
      response.should render_template(:partial => 'shared/_checkbox_select_list')
    end

    specify "Serverlevel" do
      pending "ServerLevel doesn't have association: environments"
      @server_level = create(:server_level)
      @server_level.environments << @env
      @params[:server_aspect_parent_type_and_id] = "ServerLevel::#{@server_level.id}"
      get :update_environmentsList, @params
      assigns(:available_environments).should include(@env)
      response.should render_template(:partial => 'shared/_checkbox_select_list')
    end

    specify "ServerGroup" do
      @server_group = create(:server_group)
      @server_group.environments << @env
      @params[:server_aspect_parent_type_and_id] = "ServerGroup::#{@server_group.id}"
      get :update_environmentsList, @params
      assigns(:available_environments).should include(@env)
      response.should render_template(:partial => 'shared/_checkbox_select_list')
    end

    specify "nil" do
      @params[:server_aspect_parent_type_and_id] = "ServerServer::"
          get :update_environmentsList, @params
      response.should render_template(:partial => 'shared/_checkbox_select_list')
      assigns(:available_environments).should eql(nil)
    end
  end
end
