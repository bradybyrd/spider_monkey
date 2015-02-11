require 'spec_helper'

describe ScriptsController, :type => :controller do
  before(:each) { @script = create(:general_script) }

  context 'authorization' do
    context 'authorize fails' do
      after { expect(response).to redirect_to root_path }

      context '#new' do
        include_context 'mocked abilities', :cannot, :create, :automation
        specify { get :new }
      end

      context '#create' do
        include_context 'mocked abilities', :cannot, :create, :automation
        specify { post :create }
      end

      context '#edit' do
        include_context 'mocked abilities', :cannot, :edit, :automation
        specify { get :edit, id: @script }
      end

      context '#update_script' do
        include_context 'mocked abilities', :cannot, :edit, :automation
        specify { put :update_script, id: @script }
      end

      context '#destroy' do
        include_context 'mocked abilities', :cannot, :delete, :automation
        specify { delete :destroy, id: @script }
      end

      context '#test_run' do
        include_context 'mocked abilities', :cannot, :test, :automation
        specify { get :test_run, id: @script }
      end

      context '#import_automation_scripts' do
        include_context 'mocked abilities', :cannot, :import, :automation
        specify { get :import_automation_scripts }
      end

      context '#import_local_scripts' do
        include_context 'mocked abilities', :cannot, :import, :automation
        specify { post :import_local_scripts, {} }
      end
    end
  end

  context "#new" do
    it "renders template new" do
      get :new, {"stand_alone" => true}
      response.should render_template('shared_scripts/new', :layout => false)
    end

    it "renders template detail_new without layout" do
      get :new
      response.should render_template('shared_scripts/detail_new')
    end

    it "renders template detail_new without layout" do
      xhr :get, :new
      response.should render_template('shared_scripts/detail_new', :layout => false)
    end
  end

  context "#edit" do
    it "returns error and redirects" do
      get :edit, {:id => '-1'}
      flash[:error].should include('does not exist')
      response.should redirect_to(automation_scripts_path)
    end

    it "renders template edit" do
      xhr :get, :edit, {:id => @script.id}
      response.should render_template('shared_scripts/edit', :layout => false)
    end

    it "renders template edit" do
      get :edit, {:id => @script.id}
      response.should render_template('shared_scripts/detail_edit')
    end
  end

  context "#create" do
    context "success" do
      it "redirects to index path" do
        post :create, {:script => {:name => "script name1",
                                   :content => 'script_content',
                                   :automation_category => 'General',
                                   :unique_identifier => "AutomationId1"}}
        response.should redirect_to('/environment/automation_scripts')
      end

      it "redirects to index path by ajax" do
        xhr :post, :create, {:script => {:name => "script name2",
                                         :content => 'script_content',
                                         :automation_category => 'General',
                                         :unique_identifier => "AutomationId2"}}
        response.should render_template('misc/redirect')
      end
    end

    context "fails" do
      before(:each) { @params = {:name => 'Script_name'} }

      it "shows validation errors" do
        Script.stub(:new).and_return(@script)
        @script.stub(:save).and_return(false)
        xhr :post, :create, @params
        response.should render_template('misc/error_messages_for', :layout => false)
      end

      it "renders new" do
        Script.stub(:new).and_return(@script)
        @script.stub(:save).and_return(false)
        post :create, @params
        response.should render_template('shared_scripts/detail_new')
      end

      it "returns paginated records" do
        Script.delete_all
        @scripts = 11.times.collect{create(:general_script)}
        Script.stub(:new).and_return(@script)
        @script.stub(:save).and_return(false)
        post :create, @params
        assigns(:scripts).should match_array(@scripts[0..9])
        assigns(:scripts).should_not include(@scripts[10])
      end
    end
  end

  context "#initialize_arguments" do
    it "returns flash error and redirects" do
      post :initialize_arguments, {:id => '-1'}
      flash[:error].should include('Unable to find script')
      response.should redirect_to(root_url)
    end

    it "renders partial" do
      post :initialize_arguments, {:script_id => @script.id}
      response.should render_template(:partial => 'steps/_step_script')
    end
  end

  context "#update_script" do
    context "success" do
      it "renders template update" do
        xhr :put, :update_script, {:id => @script.id,
                                   :script => {:name => 'Changed'}}
        @script.reload
        @script.name.should eql('Changed')
        response.should render_template("shared_scripts/update")
      end

      it "redirects to index" do
        put :update_script, {:id => @script.id,
                             :script => {:name => 'Changed'}}
        response.should redirect_to('/environment/automation_scripts')
      end
    end

    context "fails" do
      before(:each) do
        Script.stub(:find).and_return(@script)
        @script.stub(:update_attributes).and_return(false)
      end

      it "shows validation errors" do
        xhr :put, :update_script, {:id => @script.id,
                            :script => {:name => 'Changed'}}
        response.should render_template('misc/error_messages_for')
      end

      it "renders template edit" do
        put :update_script, {:id => @script.id,
                      :script => {:name => 'Changed'}}
        response.should render_template('shared_scripts/detail_edit')
      end
    end
  end

  it "#render_integration_header" do
    get :render_integration_header, {:script_hash => {:name => "script name1",
                                                      :content => 'script_content',
                                                      :automation_category => 'General',
                                                      :unique_identifier => "AutomationId1"}}
    response.should render_template("shared_scripts/script_integration_header.html")
  end

  context "#render_automation_form" do
    before(:each) do
      @script_hash = {:name => "script name1",
                      :content => 'script_content',
                      :automation_category => 'General',
                      :unique_identifier => "AutomationId1"}
    end
    it "renders partial automation_form" do
      post :render_automation_form, {:script_hash => @script_hash}
      response.should render_template(:partial => "shared_scripts/_automation_form")
    end

    specify "Automation" do
      post :render_automation_form, {:script_hash => @script_hash,
                                     :automation_type => "Automation"}
      response.should render_template(:partial => "shared_scripts/_automation_form")
    end

    specify "ResourceAutomation" do
      post :render_automation_form, {:script_hash => @script_hash,
                                     :automation_type => "ResourceAutomation"}
      response.should render_template(:partial => "scripted_resources/_form")
    end
  end

  context "#execute_mapped_resource_automation" do
    before(:each) do
      @plan = create(:plan, :plan_template => create(:plan_template))
      @script.project_server = create(:project_server)
      @arguments = ScriptArgument.all
      @params = {:page => 1,
                 :per_page => 10,
                 :id => @script.id,
                 :plan_id => @plan.id}
    end

    specify "with two argument values" do
      pending "can not execute script"
      value = '12','22'
      @params[:argument] = {@arguments[0].id => value}
      put :execute_mapped_resource_automation, @params
      response.should render_template(:partial => 'shared_scripts/_execute_mapped_resource_automation')
    end

    specify "with one argument values" do
      pending "can not execute script"
      @params[:argument] = {@arguments[0].id => '12'}
      put :execute_mapped_resource_automation, @params
      response.should render_template(:partial => 'shared_scripts/_execute_mapped_resource_automation')
    end

    it "returns errors" do
      @params[:argument] = {@arguments[0].id => 'value'}
      put :execute_mapped_resource_automation, @params
      response.body.should include('N.A')
    end
  end

  context "#execute_resource_automation" do
    before(:each) do
      @script.project_server = create(:project_server)
      @script.unique_identifier = "Script_id"
      @script.save
      @arguments = ScriptArgument.all
      @arguments[0].external_resource = "Script_id"
      @arguments[0].save
    end

    it "success" do
      pending "Cann't execute automation"
      post :execute_resource_automation, {:target_argument_id => @arguments[0].id}
      assigns(:external_script_output).should eql('1')
      response.body.should include('text')
    end

    it "returns errors" do
      post :execute_resource_automation, {:target_argument_id => '-1'}
      response.body.should include('N.A')
    end
  end

  it "#find_script_template" do
    xhr :get, :find_script_template, {:id => @script.id}
    response.body.should include("#{@script.content}")
  end

  it "#find_jobs" do
    pending "Connection refused Hudson Script"
    @project_server = create(:project_server)
    @script.project_server = @project_server
    xhr :get, :find_jobs, {:id => @project_server.id}
    response.body.should include("<option value=''>Select</option>")
  end

  it "#build_job_parameters" do
    pending "No route"
    get :build_job_parameters, {:script_id => @script.id,
                                :job => create(:job_run)}
    response.body.should include('current_job')
  end

  context "#update_resource_automation_parameters" do
    before(:each) do
      @app = create(:app)
      @env = create(:environment)
      @app_env = create(:application_environment,
                        :app => @app,
                        :environment => @env)
      @component = create(:component)
      @app_component = create(:application_component,
                              :app => @app,
                              :component => @component)
      @installed_component = create(:installed_component,
                                    :application_environment => @app_env,
                                    :application_component => @app_component)
      @script.unique_identifier = "Script_id"
      @script.save
      @arguments = ScriptArgument.all
      @arguments[0].external_resource = "Script_id"
      @arguments[0].save
    end

    it "with step present" do
      @step = create(:step)
      xhr :get, :update_resource_automation_parameters, {:resource_step_id => @step.id,
                                                         :resource_script_id => @script.id,
                                                         :resource_old_installed_component_id => @installed_component.id}
      response.body.should include("#{@arguments[0].id}")
    end

    it "with request present" do
      @request1 = create(:request)
      xhr :get, :update_resource_automation_parameters, {:resource_request_id => @request1.id,
                                                         :resource_component_id => @component.id,
                                                         :resource_installed_component_id => @installed_component.id,
                                                         :resource_script_type => "ResourceAutomation",
                                                         :resource_step_owner_type => 'User',
                                                         :resource_step_owner_id => @user.id,
                                                         :resource_script_id => @script.id}
      response.body.should include("#{@arguments[0].id}")
    end
  end

  context "#get_tree_elements" do
    before(:each) do
      pending "automation returns true but must return collection"
      @script.unique_identifier = "Script_id"
      @script.save
      @arguments = ScriptArgument.all
      @arguments[0].external_resource = "Script_id"
      @arguments[0].save
    end

    it "returns blank json" do
      post :get_tree_elements, {:argument_id => @arguments[0].id}
      response.body.should eql({})
    end

    it "returns script" do
      post :get_tree_elements, {:argument_id => @arguments[0].id}
      response.body.should eql(@arguments[0].to_json)
    end
  end

  context "#get_table_elements" do
    it "returns blank json" do
      @script.unique_identifier = "Script_id"
      @script.save
      @arguments = ScriptArgument.all
      @arguments[0].external_resource = "Script_id"
      @arguments[0].save
      controller.stub(:execute_table_tree_automation).and_return('success')
      post :get_table_elements, {:argument_id => @arguments[0].id,
                                 :format => 'js'}
      response.should render_template('shared_scripts/get_table_elements.js')
    end
  end

  context "#download_files" do
    it "sends file" do
      pending "cannot run file"
      get :download_files, {:path => '/file'}
      response.should_not redirect_to(root_url)
    end

    it "returns error" do
      get :download_files, {:path => '/file'}
      flash[:error].should include('does not exist')
      response.should redirect_to(root_url)
    end
  end
end
