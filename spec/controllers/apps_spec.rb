require 'spec_helper'

describe AppsController, :type => :controller do
  render_views

  #### common values
  model = App
  factory_model = :app
  can_archive = false
  #### values for index
  models_name = 'applications'
  model_index_path = '_index'
  be_sort = true
  per_page = 30
  index_flash = "No App"
  #### values for edit
  model_edit_path = '/environment/apps'
  edit_flash = nil
  http_refer = nil
  #### values for update
  update_params = {:name => 'name_ch'}
  #### values for destroy
  model_delete_path = '/apps'

  it_should_behave_like("CRUD GET index", model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like("CRUD GET new")
  it_should_behave_like("CRUD GET edit", factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like("CRUD PUT update", model, factory_model, update_params)
  it_should_behave_like("CRUD DELETE destroy", model, factory_model, model_delete_path, can_archive)

  before (:each) do
    @app = create(:app, :active => true)
  end

  context '#index' do
    describe 'authorization' do
      it_behaves_like 'main tabs authorizable', controller_action: :index,
                                                ability_object:    :applications_tab
    end
  end

  context 'authorization' do
    context 'authorize fails' do
      after { expect(response).to redirect_to root_path }

      context '#new' do
        include_context 'mocked abilities', :cannot, :create, App
        specify { get :new }
      end

      context '#show' do
        include_context 'mocked abilities', :cannot, :export, App
        specify { get :show, id: @app.id }
      end

      context '#edit' do
        include_context 'mocked abilities', :cannot, :edit, App
        specify { get :edit, id: @app.id }
      end

      context '#create' do
        include_context 'mocked abilities', :cannot, :create, App
        specify { post :create }
      end

      context '#update' do
        include_context 'mocked abilities', :cannot, :update, App
        specify { put :update, id: @app.id }
      end

      context '#destroy' do
        include_context 'mocked abilities', :cannot, :destroy, App
        specify { delete :destroy, id: @app.id }
      end

      context '#reorder_components' do
        include_context 'mocked abilities', :cannot, :reorder, ApplicationComponent
        specify { get :reorder_components, id: @app.id }
      end

      context '#reorder_environments' do
        include_context 'mocked abilities', :cannot, :reorder, ApplicationEnvironment
        specify { get :reorder_environments, id: @app.id }
      end

      context '#activate' do
        include_context 'mocked abilities', :cannot, :make_active_inactive, App
        specify { get :activate, id: @app.id }
      end

      context '#deactivate' do
        include_context 'mocked abilities', :cannot, :make_active_inactive, App
        specify { get :deactivate, id: @app.id }
      end

      context '#add_remote_components' do
        include_context 'mocked abilities', :cannot, :add_remote_component, App
        specify { get :add_remote_components, id: @app.id }
      end

      context '#create_remote_components' do
        include_context 'mocked abilities', :cannot, :add_remote_component, App
        specify { put :create_remote_components, id: @app.id }
      end

      context '#import' do
        include_context 'mocked abilities', :cannot, :import, App
        specify { post :import }
      end
    end
  end

  describe "#create" do
    context 'warning messages' do
      let(:current_user_non_root) do
        non_root_group = create(:group, root: false)
        user = @controller.current_user
        user.groups = [non_root_group]
        user
      end

      let(:edit_app_permission){ create(:permission, subject: "App", action: :update) }
      let(:create_app_permission){ create(:permission, subject: "App", action: :create) }
      let(:role_with_perm){ create(:role, permissions: [create_app_permission, edit_app_permission]) }
      let(:role_without_perm){ create(:role, permissions: [create_app_permission]) }

      let(:group_with_perm) do
        group = create(:group, name: 'Group with App edit permission', roles: [role_with_perm])
        current_user_non_root.groups << group
        group
      end

      let(:group_without_perm) do
        group = create(:group, name: 'Group without App edit permission', roles: [role_without_perm])
        current_user_non_root.groups << group
        group
      end

      let(:team_without_group_perm){ create(:team_with_apps_and_groups, groups: [group_without_perm]) }

      let(:team_with_group_perm){ create(:team_with_apps_and_groups, groups: [group_with_perm]) }

      it "doesn't adds warning for team with edit app ability" do
        post :create, {app: {name: 'Test App1', team_ids: team_with_group_perm.id }}

        flash[:notice].should include('Application was successfully created.')
        flash[:warning].should be_blank
      end


      it "adds warning team without edit app ability" do
        post :create, {app: {name: 'Test App2', team_ids: team_without_group_perm.id}}

        flash[:notice].should include('Application was successfully created.')
        flash[:warning].should include("You won't have permissions to edit created app through the selected team.")
      end
    end

    context 'with valid params' do
      it 'creates new app' do
        expect {
          post :create, app: { name: 'New app', team_ids: create(:team).id }
        }.to change(App, :count).by(1)
      end

      it 'shows creation flash message' do
        post :create, app: { name: 'New app', team_ids: create(:team).id }
        is_expected.to set_the_flash[:notice].to I18n.t(:'activerecord.notices.created', model: I18n.t(:'table.application'))
      end

      it 'redirects to edit page' do
        post :create, app: { name: 'New app', team_ids: create(:team).id }
        is_expected.to redirect_to(edit_app_path(assigns(:app)))
      end
    end

    context 'with invalid params' do
      it 'does not create new app' do
        expect {
          post :create
        }.to change(App, :count).by(0)
      end

      it 'renders "new" template' do
        post :create
        is_expected.to render_template(:new)
      end
    end
  end

  context "#show" do
    it "returns html" do
      get :show, {:id => @app.id}
      assigns(:app).should eql(@app)
      response.should render_template('apps/edit')
    end
  end

  it "#reorder_components" do
    get :reorder_components, {:id => @app.id}
    assigns(:app).should eql(@app)
    response.should render_template(:partial => '_reorder_components')
  end

  it "#reorder_environments" do
    get :reorder_environments, {:id => @app.id}
    assigns(:app).should eql(@app)
    response.should render_template(:partial => '_reorder_environments')
  end

  it "#create_default" do
    post :create_default, {:id => @app.id}
    response.should redirect_to(apps_path)
  end

  it "#add_remote_components" do
    get :add_remote_components, {:id => @app.id}
    assigns(:app).should eql(@app)
    assigns(:remote_apps).should include(@app)
    response.should render_template(:layout => false)
  end

  context "#create_remote_components" do
    it "redirect without parameters" do
      put :create_remote_components, {:id => @app.id}
      response.should redirect_to(edit_app_path(@app))
    end

    it "returns errors" do
      create_installed_component
      @attr = {:application_environment_ids_to_update => [@app_env.id],
               :installed_component_ids => [@installed_component.id],
               :id => @app.id}
      put :create_remote_components, @attr
      response.should render_template('edit')
    end
  end

  it "#application_environment_options" do
    @env = create(:environment)
    @app_env = create(:application_environment, :app => @app, :environment => @env)
    get :application_environment_options, {:app_id => @app.id}
    response.body.should include(@app_env.name)
  end

  it "#installed_component_options" do
    create_installed_component
    get :installed_component_options, {:application_environment_id => @app_env.id}
    response.body.should include(@installed_component.name)
  end

  it "#route_options" do
    @route1 = create(:route, :app => @app)
    @route2 = create(:route)
    get :route_options, {:app_id => @app.id}
    response.body.should include(@route1.name)
    response.body.should_not include(@route2.name)
  end

  it "#upload_csv" do
    @file = fixture_file_upload('/files/test_app.csv', 'csv')
    post :upload_csv, {:app_id => @app.id,
                       :csv => @file}
    response.should redirect_to(apps_path)
  end

  it "#load_env_table" do
    @env = create(:environment, :active => true)
    @app_env = create(:application_environment, :app => @app, :environment => @env)
    get :load_env_table, {:id => @app.id}
    response.should render_template(:partial => "users/form/_edit_role_by_app_environment")
    response.body.should include(@app_env.name)
  end

  describe '#import', import_export: true do
    let(:new_team) { create(:team) }

    it 'redirects to apps index' do
      xml_file = fixture_file_upload('/files/TestReleaseUI.xml', 'xml')
      get :import, { app: xml_file, team_id: new_team.id }
      response.should redirect_to(apps_path)
    end

    it 'errors on invalid json file' do
      file = fixture_file_upload('/files/bogus.json')
      get :import, { app: file, team_id: new_team.id }
      expect(flash[:error]).to include('Invalid file provided. Check log for more information.')
    end

    it 'errors on invalid xml file' do
      file = fixture_file_upload('/files/bogus.xml')
      get :import, { app: file, team_id: new_team.id }
      expect(flash[:error]).to include('Invalid file provided. Check log for more information.')
    end
  end


  it "#export", import_export: true do
    now = Time.now
    Time.stub(:now).and_return(now)
    get :export, {:id => @app.id }
    response.headers["Content-Type"].should == "text/xml"
    response.headers["Content-Disposition"].should == "attachment; filename=\"#{@app.name}_#{now.to_i}.xml\""
    response.should render_template(:file => "#{@app.name}_#{now.to_i}.xml")
  end

  def create_installed_component
    @env = create(:environment)
    @app_env = create(:application_environment, :app => @app,
                                                :environment => @env)
    @component = create(:component)
    @app_component = create(:application_component, :app => @app,
                                                    :component => @component)
    @installed_component = create(:installed_component, :application_environment => @app_env,
                                                        :application_component => @app_component)
  end
end
