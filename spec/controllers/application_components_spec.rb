require 'spec_helper'

describe ApplicationComponentsController, :type => :controller do
  before (:each) do
    @app = create(:app)
    @component = create(:component)
    @environment = create(:environment)
    @app_environment = create(:application_environment, :app => @app, :environment => @environment)
    @app_component = create(:application_component, :app => @app, :component => @component)
    @pr_server = create(:project_server)
    @installed_component = create(:installed_component,
                                  :application_environment => @app_environment,
                                  :application_component => @app_component)
    @property = create(:property)
    @property_value = create(:property_value,
                             :property => @property,
                             :value_holder => @installed_component)
    @installed_component.current_property_values << @property_value
  end
  let(:app) { create(:app) }
  let(:component) { create(:component) }
  let!(:app_comp) { create(:application_component, app: app, component: component) }


  context 'authorization' do
    context 'authorize fails' do
      after { expect(response).to redirect_to root_path }

      context '#copy_all' do
        include_context 'mocked abilities', :cannot, :create, InstalledComponent
        specify { put :copy_all, app_id: app.id }
      end

      context '#setup_clone_components' do
        include_context 'mocked abilities', :cannot, :clone, InstalledComponent
        specify { get :setup_clone_components, app_id: app.id }
      end

      context '#clone_components' do
        include_context 'mocked abilities', :cannot, :clone, InstalledComponent
        specify { get :clone_components, app_id: app.id }
      end

      context '#add_remove' do
        include_context 'mocked abilities', :cannot, :add_remove, ApplicationComponent
        specify { get :add_remove, app_id: app.id }
      end

      context '#update_all' do
        include_context 'mocked abilities', :cannot, :add_remove, ApplicationComponent
        specify { put :update_all, app_id: app.id }
      end

      context '#add_component_mapping' do
        include_context 'mocked abilities', :cannot, :map_properties, ApplicationComponent
        specify { get :add_component_mapping, app_id: app.id, id: app_comp.id }
      end

      context '#edit_component_mapping' do
        include_context 'mocked abilities', :cannot, :map_properties, ApplicationComponent
        specify { get :edit_component_mapping, app_id: app.id, id: app_comp.id }
      end

      context '#delete_mapping' do
        include_context 'mocked abilities', :cannot, :map_properties, ApplicationComponent
        specify { delete :delete_mapping, app_id: app.id, id: app_comp.id }
      end

      context '#save_mapping' do
        include_context 'mocked abilities', :cannot, :map_properties, ApplicationComponent
        specify { put :save_mapping, app_id: app.id, id: app_comp.id }
      end

      context '#edit_property_values' do
        include_context 'mocked abilities', :cannot, :edit_properties, ApplicationComponent
        specify { get :edit_property_values, app_id: app.id, id: app_comp.id }
      end

      context '#update_property_values' do
        include_context 'mocked abilities', :cannot, :edit_properties, ApplicationComponent
        specify { get :update_property_values, app_id: app.id, id: app_comp.id }
      end
    end
  end

  it "#index" do
    get :index, {:app_id => @app.id}
    response.should render_template(:partial => 'apps/_application_component_list')
  end

  it "#update" do
    put :update, {:id => @app_component.id,
                  :app_id => @app.id,
                  :component => {:insertion_point => 2}}
    response.should render_template(:partial => '_for_reorder')
    @app.application_components.find(@app_component.id).insertion_point.should eql(2)
  end

  it "#add_remove" do
    get :add_remove, {:app_id => @app.id}
    response.should render_template(:partial => 'application_components/_add_remove')
  end

  it "#copy_all" do
    @app_environment2 = create(:application_environment, :app => app, :environment => @environment)
    expect{
      put :copy_all, {:app_id => app.id}
    }.to change(app.installed_components, :count).by(1)
    response.should redirect_to(edit_app_path(app))
  end

  it "#setup_clone_components" do
    get :setup_clone_components, {:app_id => @app.id,
                                  :environment_id => @app_environment.id}
    response.should render_template(:partial => 'apps/_clone_components')
  end

  it "#clone_components" do
    expect{put :clone_components, {:app_id => @app.id,
                                   :new_environments => [{:name => 'New_env1'}],
                                   :env_to_clone_id => @app_environment.id}
    }.to change(@app.application_environments, :count).by(1)
    response.should redirect_to edit_app_path(@app)
  end

  context "#update_all" do
    it "success" do
      @component2 = create(:component)
      put :update_all, {:app_id => @app.id,
                        :new_components => [{:name => 'New_comp2'}],
                        :component_ids => [@component2.id,@component.id],
                        :format => 'js'}
      response.should render_template('misc/redirect')
    end

    it "unsuccess with invalid components" do
      @component2 = create(:component)
      put :update_all, {:app_id => @app.id,
                        :new_components => [{}],
                        :components_id => @component2.id,
                        :format => 'js'}
      response.should render_template('misc/redirect')
    end

    it "destroys app component" do
      expect{put :update_all, {:app_id => @app.id,
                               :new_components => [{}],
                               :components_ids => [@component.id]}
            }.to change(ApplicationComponent, :count).by(-1)
    end

    it "success with steps" do
      @request1 = create(:request)
      @app.requests << @request1
      @step = create(:step, :request => @request1)
      put :update_all, {:app_id => @app.id,
                        :new_components => [{:name => ''}],
                        :components_id => @component.id}
      response.should render_template('application_components/_add_remove')
    end
  end

  it "#add_component_mapping" do
    get :add_component_mapping, {:app_id => @app.id,
                                 :id => @app_component.id}
    response.should render_template(:partial => "component_mappings/_add_component_mapping")
  end

  it "#edit_component_mapping" do
    get :edit_component_mapping, {:app_id => @app.id,
                                  :id => @app_component.id}
    response.should render_template(:partial => "component_mappings/_add_component_mapping")
  end

  it "#resource_automations" do
    @script = create(:general_script)
    @app_component.application_component_mappings.build(:project_server_id => @pr_server.id,
                                                        :script_id => @script.id,
                                                        :data => 'Some Data')
    @app_component.save
    get :resource_automations, {:app_id => @app.id,
                                :id => @app_component.id,
                                :project_server_id => @pr_server.id,
                                :edit_mode => "true"}
    response.should render_template(:partial => "component_mappings/_resource_automations")
  end

  context "#filter_arguments" do
    it "returns flash 'no script'" do
      get :filter_arguments, {:app_id => @app.id,
                              :id => @app_component.id,
                              :project_server_id => @pr_server.id}
      response.body.should be_blank
      flash.now[:error].should include('Unable to find component mappings')
    end

    it "returns mapped script" do
      @script = create(:general_script)
      @app_component.application_component_mappings.build(:project_server_id => @pr_server.id,
                                                          :script_id => @script.id,
                                                          :data => 'Some Data')
      @app_component.save
      get :filter_arguments, {:app_id => @app.id,
                              :id => @app_component.id,
                              :project_server_id => @pr_server.id,
                              :script_id => @script.id,
                              :edit_mode => 'true'}
      assigns(:script).should eql(@script)
    end

    it "finds script by id and renders partial" do
      @script = create(:general_script)
      get :filter_arguments, {:app_id => @app.id,
                              :id => @app_component.id,
                              :project_server_id => @pr_server.id,
                              :script_id => @script.id}
      response.should render_template(:partial => "component_mappings/_filter_arguments")
    end
  end

  it "#delete_mapping" do
    @script = create(:general_script)
    @app_component.application_component_mappings.build(:project_server_id => @pr_server.id,
                                                        :script_id => @script.id,
                                                        :data => 'Some Data')
    @app_component.save
    expect{delete :delete_mapping, {:app_id => @app.id,
                                    :id => @app_component.id,
                                    :project_server_id => @pr_server.id,
                                    :format => 'js'}
          }.to change(ApplicationComponentMapping, :count).by(-1)
    response.should render_template('misc/redirect')
  end

  context "#save_mapping" do
    before(:each) do
      @script = create(:general_script)
      @app_component.application_component_mappings.build(:project_server_id => @pr_server.id,
                                                          :script_id => @script.id,
                                                          :data => 'Some Data')
      @app_component.save
    end

    it "updates current mapping" do
      @arguments = ScriptArgument.all
      put :save_mapping, {:app_id => @app.id,
                          :id => @app_component.id,
                          :edit_mode => 'true',
                          :project_server_id => @pr_server.id,
                          :script_id => @script.id,
                          :argument => {@arguments[0] => 'val1',
                                        @arguments[1] => 'val2'},
                          :format => 'js'}
      @app_component.application_component_mappings.first.script_id.should eql(@script.id)
      response.should render_template('misc/redirect')
    end

    it "creates new component mapping" do
      @pr_server2 = create(:project_server)
      @arguments = ScriptArgument.all
      expect{put :save_mapping, {:app_id => @app.id,
                                 :id => @app_component.id,
                                 :project_server_id => @pr_server2.id,
                                 :script_id => @script.id,
                                 :argument => {@arguments[0] => 'val1',
                                               @arguments[1] => 'val2'}}
            }.to change(ApplicationComponentMapping, :count).by(1)
    end

    it "returns errors" do
      @arguments = ScriptArgument.all
      put :save_mapping, {:app_id => @app.id,
                          :id => @app_component.id,
                          :project_server_id => @pr_server.id,
                          :script_id => @script.id,
                          "tree_renderer_#{@arguments[0].id}" => ['val01','val02', 'val03'],
                          :format => 'js'}
      response.should render_template('misc/update_div.js')
    end
  end

  context "#edit_property_values" do

    it "renders template edit_property_values" do
      @app_environments = 3.times.collect{create(:application_environment,
                                                 :app => create(:app),
                                                 :environment => create(:environment))}
      @application_component = create(:application_component,
                                      app: @app_environments[0].app,
                                      component: create(:component))
      @app_environments.each{ |el| @application_component.application_environments << el }
      get :edit_property_values, {:app_id => @app_environments[0].app.id,
                                  :id => @application_component.id}
      assigns(:app_environments).should == @app_environments
      response.should render_template('edit_property_values')
    end

    it "renders partial show_property" do
      @property = create(:property)
      get :edit_property_values, {:app_id => @app.id,
                                  :id => @app_component.id,
                                  :property_number => 1,
                                  :property_id => @property.id,
                                  :show_property => true}
      response.should render_template(:partial => 'application_components/_show_properties')
    end

    it "renders partial edit_property" do
      @property = create(:property)
      get :edit_property_values, {:app_id => @app.id,
                                  :id => @app_component.id,
                                  :property_numbers => [1],
                                  :property_ids => [@property.id],
                                  :show_view => true}
      response.should render_template(:partial => 'application_components/_edit_property_values')
    end

    it "renders partial application_components/add_property" do
      get :edit_property_values, {:app_id => @app.id,
                                  :id => @app_component.id,
                                  :add_property => true}
      response.should render_template(:partial => 'application_components/_add_property')
    end
  end

  context "#update_property_values" do
    before(:each) do
      @component_property = create(:component_property, :component => @component, :property => @property)
    end

    it "renders template property_success_create" do
      put :update_property_values, {:app_id => @app.id,
                                    :id => @app_component.id,
                                    :properties => {:name => 'pr1',:active => true},
                                    :format => 'js'}
      response.should render_template('application_components/property_success_create')
    end

    it "renders template update_div" do
      put :update_property_values, {:app_id => @app.id,
                                    :id => @app_component.id,
                                    :properties => {:name => '',:active => true},
                                    :format => 'js'}
      response.should render_template('misc/update_div')
    end

    it "removes property" do
      expect{put :update_property_values, {:app_id => @app.id,
                                          :id => @app_component.id,
                                          :component_property => {@property.id => @property.id},
                                          "property_values_#{@app_environment.id}" => {@property.id =>
                                                                                       @property_value.value},
                                          :format => 'js'}
            }.to change(ComponentProperty, :count).by(-1)
      response.should render_template('update_property_values')
    end

    it "updates property" do
      put :update_property_values, {:app_id => @app.id,
                                    :id => @app_component.id,
                                    "property_values_#{@app_environment.id}" => {@property.id => "new_value"},
                                    :update_comp_prop_assoc => true,
                                    :format => 'js'}
      @installed_component.current_property_values.find_by_property_id(@property.id).value.should eql('new_value')
      assigns(:success).should eql(true)
      response.should render_template('update_property_values')
    end

    it "#update_value_for_uninstalled_component" do
      @app_component.application_environments.delete_all
      expect{put :update_property_values, {:app_id => @app.id,
                                           :id => @app_component.id,
                                           :component_property => {@property.id => @property.id},
                                           :property_id_for_uninsalled_component => {@property.id => @property.id},
                                           "property_values_#{@app_environment.id}" => {@property.id => "new_value"},
                                           :format => 'js'}
            }.to change(ComponentProperty, :count).by(-1)
      assigns(:success).should eql(true)
    end
  end
end
