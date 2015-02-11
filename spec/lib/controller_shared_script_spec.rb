require 'spec_helper'

describe ControllerSharedScript, :type => :controller do
  controller do
    include ControllerSharedScript

    def test_index
      index
    end

    def test_new
      new
    end

    def test_create
      create
    end

    def test_edit
      edit
    end

    def test_update
      update
    end

    def test_destroy
      destroy
    end

    def test_import_select_script
      import_select_script
    end

    def test_import
      import
    end

    def test_import_local_scripts_list
      import_local_scripts_list
    end

    def test_import_automation_scripts
      import_automation_scripts
    end

    def test_render_automation_types
      render_automation_types
    end

    def test_import_local_scripts
      import_local_scripts
    end

    def test_import_local_scripts_preview
      import_local_scripts_preview
    end

    def test_import_scripts_list
      result = import_scripts_list
      if result.include?("No Integration")
        render :nothing => true
      end
    end

    def test_test_run
      test_run
    end

    def test_map_properties_to_argument
      map_properties_to_argument
    end

    def test_update_argument_properties
      update_argument_properties
    end

    def test_update_argument_server_properties
      update_argument_server_properties
    end

    def test_multiple_application_environment_options
      multiple_application_environment_options
    end

    def test_component_options
      component_options
    end

    def test_property_options
      property_options
    end

    def test_app_env_remote_options
      app_env_remote_options
    end

    def test_installed_component_remote_options
      installed_component_remote_options
    end

    def test_default_values_from_properties
      default_values_from_properties
    end

    def test_default_values_from_server_properties
      default_values_from_server_properties
    end

    def test_server_property_options
      server_property_options
    end

    def test_build_script_list
      build_script_list
    end

    #####private####

    def test_render_new
      render_new
    end

    def test_render_edit
      render_edit
    end

    def test_rearrange_script_files(script_files,folder,sub_folder)
      rearrange_script_files(script_files,folder,sub_folder)
    end

    def test_build_integration_parameters(content)
      build_integration_parameters(content)
    end

    def test_parse_arguments(content)
      parse_arguments(content)
    end

    def test_parsed_arguments(content)
      parsed_arguments(content)
    end

    ####self

    def import_from_library(script_files = nil, folder = nil, sub_folder = nil, project_server_id = nil)
    end
  end

  let(:script) { create(:general_script) }

  it "#index" do
    routes.draw { get "test_index" => "anonymous#test_index"}
    controller.stub(:use_template).and_return('bladelogic')
    get :test_index
    response.should redirect_to('/environment/bladelogic')
  end

  it "#new" do
    routes.draw { get "test_new" => "anonymous#test_new"}
    controller.stub(:associated_model).and_return(Script)
    get :test_new
    response.should render_template('shared_scripts/detail_new')
  end

  describe "#create" do
    before(:each) do
      routes.draw { post "test_create" => "anonymous#test_create"}
      controller.stub(:associated_model).and_return(Script)
      controller.stub(:bladelogic?).and_return(false)
    end

    it "success" do
      params = {:script => {:name => 'name1',
                            :content => script.content,
                            :automation_category => 'General',
                            :unique_identifier => "Automation 1"}}
      controller.stub(:params).and_return(params)
      expect{ post :test_create }.to change(Script, :count).by(1)
      response.should redirect_to('/environment/automation_scripts')
    end

    it "returns paginated records" do
      scripts = 11.times.collect { create(:general_script) }
      params = {:script => {:name => 'name1',
                            :content => ''}}
      controller.stub(:params).and_return(params)
      post :test_create
      assigns(:scripts).should match_array scripts.first(10)
      assigns(:scripts).should_not include(scripts[10])
    end

    it "fails" do
      params = {:script => {:name => 'name1',
                            :content => '',
                            :automation_category => 'General',
                            :unique_identifier => "Automation 1"}}
      controller.stub(:params).and_return(params)
      expect{ post :test_create }.to change(Script, :count).by(0)
      response.should render_template('shared_scripts/detail_new')
    end
  end

  it "#edit" do
    routes.draw { get "test_edit" => "anonymous#test_edit"}
    controller.stub(:bladelogic?).and_return(false)
    controller.stub(:params).and_return({:id => script.id})
    get :test_edit
    response.should render_template('shared_scripts/detail_edit')
  end

  describe "#update" do
    let!(:route) { routes.draw { put "test_update" => "anonymous#test_update"} }

    describe "success" do
      let(:params) { {:script => {:name => 'name1'},
                      :id => script.id} }
      let!(:send_parms) { controller.stub(:params).and_return(params) }

      it "changed name and redirects to index path" do
        controller.stub(:bladelogic?).and_return(false)
        put :test_update
        script.reload
        script.name.should eql('name1')
        response.should redirect_to('/environment/automation_scripts')
      end

      it "renders update" do
        controller.stub(:bladelogic?).and_return(false)
        xhr :put, :test_update
        response.should render_template('shared_scripts/update')
      end

      it "renders bladelogic update" do
        controller.stub(:bladelogic?).and_return(true)
        controller.stub(:find_script).and_return(create(:bladelogic_script))
        params[:script][:script_type] = "BladelogicScript"
        xhr :put, :test_update
        response.should render_template('shared_scripts/bladelogic/update')
      end
    end

    describe "fails" do
      before(:each) do
        controller.stub(:find_script).and_return(script)
        script.stub(:update_attributes).and_return(false)
        controller.stub(:bladelogic?).and_return(false)
      end

      it "renders edit" do
        params = {:script => {:name => 'name1'},
                  :id => script.id}
        controller.stub(:params).and_return(params)
        put :test_update
        response.should render_template("shared_scripts/detail_edit")
      end

      it "returns paginated records" do
        Script.delete_all
        scripts = 11.times.collect{ create(:general_script) }
        params = {:script => {:name => 'name1'},
                  :id => scripts[0].id,
                  :per_page => 10,
                  :page => 1}
        controller.stub(:params).and_return(params)
        put :test_update
        assigns(:scripts).should match_array scripts.first(10)
        assigns(:scripts).should_not include(scripts[10])
      end
    end
  end

  describe "#destroy" do
    let!(:route) { routes.draw { put "test_delete" => "anonymous#test_destroy"} }

    it "deletes bladelogic script and redirects to index path" do
      controller.stub(:bladelogic?).and_return(true)
      script = create(:bladelogic_script)
      expect{ delete :test_destroy, {:id => script.id}
            }.to change(BladelogicScript, :count).by(-1)
      response.should redirect_to('/environment/bladelogic')
    end

    it "deletes script" do
      controller.stub(:bladelogic?).and_return(false)
      script = create(:general_script)
      script.archive_number = 1
      script.archived_at = Date.new
      script.save!
      controller.stub(:find_script).and_return(script)
      script.stub(:automation_type).and_return('Automation')
      expect{ delete :test_destroy, {:id => script.id}
            }.to change(Script, :count).by(-1)
    end

    it "deletes ResourceAutomation script" do
      controller.stub(:bladelogic?).and_return(false)
      script = create(:general_script)
      script.archive_number = 2
      script.archived_at = Date.new
      script.save!
      expect{ delete :test_destroy, {:id => script.id}
            }.to change(Script, :count).by(-1)
    end

    it "returns flash error" do
      script_content = <<-'SCRIPT_CONTENT'
                      ### <u>def execute(script_params, parent_id, offset, max_records)</u>
                      # argument1:
                      #   name: the first argument
                      # argument2:
                      #   name: the second argument
                      ###
                      echo 1
                      #Close the file
                      @hand.close
      SCRIPT_CONTENT
      controller.stub(:bladelogic?).and_return(false)
      script = create(:general_script, :automation_type => "ResourceAutomation",
                                       :unique_identifier => 'some id',
                                       :content => script_content)
      ScriptArgument.stub(:find_all_by_external_resource).and_return([1])
      expect{ delete :test_destroy, {:id => script.id}
            }.to change(Script, :count).by(0)
      flash[:error].should include("this script is being used")
    end
  end

  it "#import_select_script" do
    routes.draw { get "test_import_select_script" => "anonymous#test_import_select_script"}
    get :test_import_select_script
    response.should render_template('shared_scripts/import', :layout => false)
  end

  it "#import" do
    routes.draw { get "test_import" => "anonymous#test_import"}
    get :test_import
    response.should render_template('shared_scripts/import', :layout => false)
  end

  describe "#import_local_scripts_list" do
    let!(:route) {routes.draw { get "test_import_local_scripts_list" => "anonymous#test_import_local_scripts_list"} }

    specify "bladelogic_scripts" do
      controller.stub(:params).and_return({:folder => 'bladelogic'})
      get :test_import_local_scripts_list
      response.should render_template('shared_scripts/import_local_scripts_list')
    end

    specify "automation_scripts" do
      controller.stub(:params).and_return({:folder => 'automation', :sub_folder => 'General'})
      get :test_import_local_scripts_list
      response.should render_template('shared_scripts/import_local_scripts_list')
    end

    it "returns flash" do
      controller.stub(:script_files).and_return(true)
      get :test_import_local_scripts_list
      flash[:notice].should eql("Missing or invalid script type.")
    end
  end

  it "#import_automation_scripts" do
    routes.draw { get "test_import_automation_scripts" => "anonymous#test_import_automation_scripts"}
    get :test_import_automation_scripts
    response.should render_template('shared_scripts/import_automation_scripts', :layout => false)
  end

  it "#render_automation_types" do
    routes.draw { get "test_render_automation_types" => "anonymous#test_render_automation_types"}
    controller.stub(:params).and_return({:automation_type => "automation"})
    List.stub(:get_list_items).and_return(["Hudson/Jenkins", "Jira"])
    get :test_render_automation_types
    result = "<option value=\"\">Select</option>\n<option value=\"Hudson\">Hudson/Jenkins</option>\n<option value=\"Jira\">Jira</option>"
    response.body.should eql(result)
  end

  describe "#import_local_scripts" do
    let!(:route) {routes.draw { get "test_import_local_scripts" => "anonymous#test_import_local_scripts"} }

    specify "bladelogic_scripts" do
      controller.stub(:import_from_library).and_return(true)
      controller.stub(:params).and_return({:folder => 'bladelogic'})
      get :test_import_local_scripts
      response.should redirect_to('/environment/bladelogic')
    end

    specify "automation_scripts" do
      controller.stub(:import_from_library).and_return(true)
      controller.stub(:params).and_return({:folder => 'automation'})
      xhr :get, :test_import_local_scripts
      response.should render_template("misc/redirect")
    end

    describe "fails" do
      render_views
      it "renders template" do
        controller.stub(:import_from_library).and_return([false, ["import error"]])
        controller.stub(:params).and_return({:folder => 'automation'})
        xhr :get, :test_import_local_scripts
        response.should render_template("misc/update_div")
        assigns(:div_content).should include("import error")
      end

      it "returns flash and redirects" do
        controller.stub(:import_from_library).and_return(false)
        controller.stub(:params).and_return({:folder => 'automation'})
        get :test_import_local_scripts
        flash[:error].should eql("Error importing scripts.")
        response.should redirect_to('/environment/automation_scripts')
      end
    end
  end

  describe "#import_local_scripts_preview" do
    let!(:route) {routes.draw { get "test_import_local_scripts_preview" => "anonymous#test_import_local_scripts_preview"} }

    it "success" do
      controller.stub(:params).and_return({:path => "#{Rails.root}/lib/script_support/LIBRARY/bladelogic/bl_create_job.py"})
      get :test_import_local_scripts_preview
      assigns(:content).should_not include("Script not found at ")
      response.should render_template('shared_scripts/import_local_scripts_preview')
    end

    it "fails" do
      get :test_import_local_scripts_preview
      response.should render_template('shared_scripts/import_local_scripts_preview')
      assigns(:content).should eql("Script not found at ")
    end
  end

  describe "#import_scripts_list" do
    let!(:route) {routes.draw { get "test_import_scripts_list" => "anonymous#test_import_scripts_list"} }
    let!(:pr_server) { create(:project_server) }

    it "returns text" do
      controller.stub(:params).and_return({:integration_id => pr_server.id})
      ProjectServer.stub(:find).and_return(nil)
      get :test_import_scripts_list, {:not_renders => true}
      response.code.should eql("200")
    end

    it "renders template" do
      controller.stub(:params).and_return({:integration_id => pr_server.id})
      Script.stub(:import_script_list).and_return("Scripts")
      get :test_import_scripts_list
      response.should render_template('shared_scripts/import_script_list')
    end
  end

  describe "#test_run" do
    let!(:route) {routes.draw { get "test_test_run" => "anonymous#test_test_run"} }

    context "without arguments" do
      before(:each) do
        controller.stub(:find_script).and_return(script)
        script.arguments.stub(:blank?).and_return(true)
        script.stub(:test_run!).and_return(true)
      end

      it "renders template bladelogic/test_run" do
        script.stub(:class).and_return(BladelogicScript)
        get :test_test_run
        response.should render_template('shared_scripts/bladelogic/test_run')
      end

      it "renders template test_run" do
        get :test_test_run
        response.should render_template('shared_scripts/test_run')
      end
    end

    context "with arguments" do
      it "renders template bladelogic/add_aruments" do
        controller.stub(:find_script).and_return(create(:bladelogic_script))
        get :test_test_run
        response.should render_template('shared_scripts/bladelogic/add_arguments')
      end

      it "renders template add_aruments" do
        controller.stub(:find_script).and_return(create(:general_script))
        get :test_test_run
        response.should render_template('shared_scripts/add_arguments')
      end
    end
  end

  describe "#map_properties_to_argument" do
    let!(:route) {routes.draw { get "test_map_properties_to_argument" => "anonymous#test_map_properties_to_argument"} }

    it "renders template bladelogic/map_properties_to argument" do
      script = create(:bladelogic_script)
      controller.stub(:params).and_return({:script_argument_id => script.arguments.first})
      controller.stub(:find_script).and_return(script)
      get :test_map_properties_to_argument
      response.should render_template('shared_scripts/bladelogic/map_properties_to_argument')
    end

    it "renders template map_properties_to argument" do
      controller.stub(:params).and_return({:script_argument_id => script.arguments.first})
      controller.stub(:find_script).and_return(script)
      get :test_map_properties_to_argument
      response.should render_template('shared_scripts/map_properties_to_argument')
    end
  end

  describe "#update_argument_properties" do
    let!(:route) {routes.draw { get "test_update_argument_properties" => "anonymous#test_update_argument_properties"} }

    before(:each) do
      create_installed_component
      controller.stub(:find_script).and_return(script)
      @property = create(:property)
      @params = {:script_argument_id => script.arguments.first,
                 :application_environment_ids => [@app_env.id],
                 :property_ids => [@property.id],
                 :app_ids => [@app.id],
                 :component_ids => [@component.id]}
      @installed_component.properties << @property
      controller.stub(:params).and_return(@params)
    end

    it "renders partial and updates property" do
      expect { get :test_update_argument_properties
             }.to change(ScriptArgumentToPropertyMap, :count).by(1)
      response.should render_template(:partial => 'shared_scripts/_parsed_parameters')
    end

    it "renders partial update property with parse params" do
      @params[:application_environment_ids] = ["#{@env.id}_#{@app_env.id}"]
      expect { get :test_update_argument_properties
             }.to change(ScriptArgumentToPropertyMap, :count).by(1)
      response.should render_template(:partial => 'shared_scripts/_parsed_parameters')
    end
  end

  it "#update_argument_server_properties" do
    routes.draw { get "test_update_argument_server_properties" => "anonymous#test_update_argument_server_properties"}
    controller.stub(:find_script).and_return(script)
    property = create(:property)
    server = create(:server)
    server.properties << property
    @params = {:script_argument_id => script.arguments.first,
               :server_ids => [server.id],
               :property_ids => [property.id]}
    controller.stub(:params).and_return(@params)
    expect { get :test_update_argument_server_properties
           }.to change(ScriptArgumentToPropertyMap, :count).by(1)
    response.should render_template(:partial => 'shared_scripts/_parsed_parameters')
  end

  describe "#multiple_application_environment_options" do
    let!(:route) {routes.draw { get "test_multiple_application_environment_options" => "anonymous#test_multiple_application_environment_options"} }

    it "renders text" do
      app = create(:app)
      controller.stub(:params).and_return({:app_ids => [app.id]})
      #controller.stub(:current_user).and_return(create(:old_user))
      get :test_multiple_application_environment_options
      response.body.should include(app.name)
    end

    it "renders nothing" do
      get :test_multiple_application_environment_options
      response.code.should eql('200')
    end
  end

  describe "#component_options" do
    let!(:route) {routes.draw { get "test_component_options" => "anonymous#test_component_options"} }

    before(:each) do
      create_installed_component
      @params = {:application_environment_ids => [@app_env.id],
                 :app_ids => [@app.id]}
      controller.stub(:params).and_return(@params)
    end

    it "returns components" do
      get :test_component_options
      response.body.should include(@component.name)
    end

    it "returns components with parse params" do
      @params[:application_environment_ids] = ["#{@env.id}_#{@app_env.id}"]
      get :test_component_options
      response.body.should include(@component.name)
    end
  end

  it "#property_options" do
    component = create(:component)
    property = create(:property)
    create(:component_property, :component => component, :property => property)
    routes.draw { get "test_property_options" => "anonymous#test_property_options"}
    @params = {:component_ids => [component.id]}
    controller.stub(:params).and_return(@params)
    get :test_property_options
    response.body.should include(property.name)
  end

  describe "#app_env_remote_options" do
    let!(:route) {routes.draw { get "test_app_env_remote_options" => "anonymous#test_app_env_remote_options"} }

    it "returns nothing" do
      get :test_app_env_remote_options
      response.body.should eql("")
    end

    it "returns app environment" do
      create_installed_component
      controller.stub(:params).and_return({:app_id => @app.id})
      get :test_app_env_remote_options
      response.body.should include(@app_env.name)
    end
  end

  describe "#installed_component_remote_options" do
    let!(:route) {routes.draw { get "test_installed_component_remote_options" => "anonymous#test_installed_component_remote_options"} }

    it "returns nothing" do
      get :test_installed_component_remote_options
      response.body.should eql("")
    end

    it "returns installed components" do
      create_installed_component
      controller.stub(:params).and_return({:app_env_id => @app_env.id})
      get :test_installed_component_remote_options
      response.body.should include(@installed_component.name)
    end
  end

  describe "#default_values_from_properties" do
    let!(:route) { routes.draw { get "test_default_values_from_properties" => "anonymous#test_default_values_from_properties"} }

    it "renders partial bladelogic/step_script" do
      create_installed_component
      controller.stub(:find_script).and_return(create(:bladelogic_script))
      controller.stub(:params).and_return({:installed_component_id => @installed_component.id})
      get :test_default_values_from_properties
      response.should render_template('steps/bladelogic/_step_script')
    end

    it "renders partial step_script" do
      controller.stub(:find_script).and_return(script)
      get :test_default_values_from_properties
      response.should render_template('steps/_step_script')
    end
  end

  describe "#default_values_from_server_properties" do
    let!(:route) { routes.draw { get "test_default_values_from_server_properties" => "anonymous#test_default_values_from_server_properties"} }
    before(:each) { controller.stub(:find_server).and_return(create(:server)) }

    it "renders partial bladelogic/step_script" do
      controller.stub(:find_script).and_return(create(:bladelogic_script))
      get :test_default_values_from_server_properties
      response.should render_template('steps/bladelogic/_step_script')
    end

    it "renders partial step_script" do
      controller.stub(:find_script).and_return(script)
      get :test_default_values_from_server_properties
      response.should render_template('steps/_step_script')
    end
  end

  it "#server_property_options" do
    routes.draw { get "test_server_property_options" => "anonymous#test_server_property_options"}
    server = create(:server)
    property = create(:property)
    server.properties << property
    controller.stub(:find_servers).and_return([server])
    get :test_server_property_options
    response.body.should include(property.name)
  end

  describe "#build_script_list" do
    let!(:route) { routes.draw { get "test_build_script_list" => "anonymous#test_build_script_list"} }

    specify "bladelogic" do
      script = create(:bladelogic_script)
      controller.stub(:params).and_return({"script_class" => "BladelogicScript"})
      get :test_build_script_list
      response.body.should include(script.name)
    end

    specify "automation scripts" do
      script.automation_type = 'Automation'
      script.begin_testing!
      script.save!
      controller.stub(:params).and_return({"script_class" => script.automation_category})
      get :test_build_script_list
      response.body.should include(script.name)
    end
  end

  #####private####

  describe "#render_new" do
    before(:each) { routes.draw { get "test_render_new" => "anonymous#test_render_new"} }

    describe "with xhr request" do
      it "renders bladelogic detail_new" do
        controller.stub(:associated_model).and_return(BladelogicScript)
        xhr :get, :test_render_new
        response.should render_template('shared_scripts/bladelogic/detail_new', :layout => false)
      end

      it "renders detail_new" do
        controller.stub(:associated_model).and_return(Script)
        xhr :get, :test_render_new
        response.should render_template('shared_scripts/detail_new', :layout => false)
      end
    end

    describe "with get request" do
      it "renders bladelogic detail_new" do
        controller.stub(:associated_model).and_return(BladelogicScript)
        get :test_render_new
        response.should render_template('shared_scripts/bladelogic/detail_new')
      end

      it "renders detail_new" do
        controller.stub(:associated_model).and_return(Script)
        get :test_render_new
        response.should render_template('shared_scripts/detail_new')
      end
    end

    it "renders new template" do
      controller.stub(:params).and_return({"stand_alone" => true})
      get :test_render_new
      response.should render_template('shared_scripts/new')
    end
  end

  describe "#render_edit" do
    before(:each) { routes.draw { get "test_render_edit" => "anonymous#test_render_edit"} }

    describe "with xhr request" do
      it "renders bladelogic detail_new" do
        controller.stub(:associated_model).and_return(BladelogicScript)
        xhr :get, :test_render_edit
        response.should render_template('shared_scripts/bladelogic/edit', :layout => false)
      end

      it "renders detail_new" do
        controller.stub(:associated_model).and_return(Script)
        xhr :get, :test_render_edit
        response.should render_template('shared_scripts/edit', :layout => false)
      end
    end

    describe "with get request" do
      it "renders bladelogic detail_new" do
        controller.stub(:associated_model).and_return(BladelogicScript)
        get :test_render_edit
        response.should render_template('shared_scripts/bladelogic/detail_edit')
      end

      it "renders detail_new" do
        controller.stub(:associated_model).and_return(Script)
        get :test_render_edit
        response.should render_template('shared_scripts/detail_edit')
      end
    end
  end

  describe "#rearrange_script_files" do
    specify "with sub_folder" do
      controller.test_rearrange_script_files(['ara_install.rb'], 'automation', 'General').should include('ara_install.rb')
    end

    specify "without sub_folder" do
      controller.test_rearrange_script_files(['bl_create_job.py'], 'bladelogic', nil).should include('bl_create_job.py')
    end
  end

  describe "#build_integration_parameters" do
    it "returns text 'not found'" do
      controller.test_build_integration_parameters("Some content").should eql("\n# Integration server not found #")
    end

    it "returns content" do
      project_server = create(:project_server)
      controller.instance_variable_set("@project_server", project_server)
      result = controller.test_build_integration_parameters("Some content")
      result.should include("[integration_id=#{project_server.id}")
      result.should include("Some content")
    end
  end

  it "#parse_arguments" do
    controller.test_parse_arguments("###\n# server_profile:\n#   name: Name of server profile\n###").should eql("# server_profile:\n#   name: Name of server profile")
  end

  describe "#parsed_arguments" do
    it "returns header" do
      result = controller.test_parsed_arguments("###\n# server_profile:\n#   name: Name of server profile\n###")
      result.should eql({"server_profile" => {"name" => 'Name of server profile'}})
    end

    it "returns nothing" do
      controller.test_parsed_arguments("bbb").should eql({})
    end
  end

  def create_installed_component
    @app = create(:app)
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

describe ControllerSharedScript, :type => :controller do
  controller do
    include ControllerSharedScript

    #####protected##

    def test_find_script
      find_script
    end

    def test_find_servers
      find_servers
    end

    def test_find_server
      find_server
    end

    def test_associated_model
      associated_model
    end

    def test_index_path
      index_path
    end

    def test_test_argument_values(script, installed_component = nil)
      test_argument_values(script, installed_component = nil)
    end

    def test_import_from_library(script_files = nil, folder = nil, sub_folder = nil, project_server_id = nil)
      import_from_library(script_files, folder, sub_folder, project_server_id)
    end
  end

  let(:script) { create(:general_script) }

  it "#find_script" do
    controller.stub(:bladelogic?).and_return(false)
    controller.stub(:params).and_return({:id => script.id})
    controller.test_find_script.should eql(script)
  end

  describe "#find_servers" do
    it "returns servers" do
      server_ids = []
      servers = 2.times.collect { create(:server) }
      servers.each { |el| server_ids << el.id }
      controller.stub(:params).and_return(:server_ids => [server_ids])
      controller.test_find_servers.should eql(servers)
    end

    it "returns server_aspects" do
      aspect_ids = []
      server_aspects = 2.times.collect { create(:server_aspect, :server_level => create(:server_level)) }
      server_aspects.each { |el| aspect_ids << el.id }
      controller.stub(:params).and_return(:server_aspect_ids => aspect_ids)
      controller.test_find_servers.should eql(server_aspects)
    end
  end

  describe "#find_server" do
    it "returns server" do
      server = create(:server)
      controller.stub(:params).and_return(:server_id => server.id)
      controller.test_find_server.should eql(server)
    end

    it "returns server_aspect" do
      server_aspect = create(:server_aspect, :server_level => create(:server_level))
      controller.stub(:params).and_return(:server_aspect_id => server_aspect.id)
      controller.test_find_server.should eql(server_aspect)
    end
  end

  describe "#associated_model" do
    it "returns BladelogicScript" do
      controller.stub(:bladelogic?).and_return(true)
      controller.test_associated_model.should eql(BladelogicScript)
    end

    it "returns Script" do
      controller.stub(:bladelogic?).and_return(false)
      controller.test_associated_model.should eql(Script)
    end
  end

  describe "#index_path" do
    let!(:params) { controller.stub(:params).and_return({:page => 1, :key => 'Dev'}) }

    it "return bladelogic path" do
      controller.stub(:bladelogic?).and_return(true)
      controller.test_index_path.should eql(bladelogic_path(:page => 1, :key => 'Dev'))
    end

    it "returns automation scripts path" do
      controller.stub(:bladelogic?).and_return(false)
      controller.test_index_path.should eql(automation_scripts_path(:page => 1, :key => 'Dev'))
    end
  end

  describe "#test_argument_values" do
    it "returns blank values" do
      result = {}
      script.arguments.each {|el| result[el.id] = {"value" => ""}}
      controller.test_test_argument_values(script, nil).should eql(result)
    end

    it "returns values of installed component" do
      create_installed_component
      result = {}
      script.arguments.each {|el| result[el.id] = {"value" => ""}}
      controller.test_test_argument_values(script, @installed_component).should eql(result)
    end
  end

  describe "#import_from_library" do
    it "Remedy returns error 'server not found'" do
      result = controller.test_import_from_library(['remedy_activity_statuses.rb'], 'resource_automation', 'BMC Remedy 7.6.x', create(:project_server).id)
      result.should eql([false, ["remedy_activity_statuses.rb: Integration server type of Remedy via AO not found."]])
    end

    it "BAA returns error 'server not found'" do
      result = controller.test_import_from_library(['baa_jobs.rb'], 'resource_automation', 'BMC Application Automation 8.2', create(:project_server).id)
      result.should eql([false, ["baa_jobs.rb: Integration server type of BMC Application Automation not found."]])
    end

    it "RLM returns error 'server not found'" do
      result = controller.test_import_from_library(['rlm_routes.rb'], 'resource_automation', 'RLM Deployment Engine', create(:project_server).id)
      result.should eql([false, ["rlm_routes.rb: Integration server type of <u>RLM Deployment Engine</u> not found."]])
    end

    it "bladelogic success" do
      result = controller.test_import_from_library(['bl_create_job.py'], 'bladelogic', nil)
      result.should eql([true, []])
    end

    it "hudson success" do
      result = controller.test_import_from_library(['hudson_choose_job.rb'], 'resource_automation', 'Hudson', create(:project_server).id)
      result.should eql([true, []])
    end

    it "hudson success with aasm_state as released" do
      result = controller.test_import_from_library(['hudson_choose_job.rb'], 'resource_automation', 'Hudson', create(:project_server).id)
      script = Script.first
      expect(script.aasm_state).to eq('released')
    end

    it "returns errors 'Integration server not found'" do
      result = controller.test_import_from_library(['hudson_choose_job.rb'], 'resource_automation', 'Hudson')
      result.should eql([false, ["hudson_choose_job.rb: Integration server type of Hudson not found."]])
    end

    it "return errors cann't import" do
      controller.test_import_from_library().should eql([false, ["Script folder can't be blank", "Can't Import without script"]])
    end
  end

  def create_installed_component
    @app = create(:app)
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
