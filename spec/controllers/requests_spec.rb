require 'spec_helper'

describe RequestsController, :type => :controller do
  before(:each) do
    @app = create(:app)
    @env = create(:environment)
    @app_env = create(:application_environment, :app => @app, :environment => @env)
    AssignedEnvironment.create!(:environment_id => @env.id, :assigned_app_id => @app.assigned_apps.first.id, :role => @user.roles.first)
    @package_content = create(:package_content)
  end

  let(:request1) { create(:request, :apps => [@app], :environment_id => @env.id) }
  let(:request_id) { request1.id   + GlobalSettings[:base_request_number] }

  context 'authorization' do
    context 'authorize fails' do
      after { expect(response).to redirect_to root_path }

      describe 'scheduling' do
        let(:activity) { create(:activity, requests: [request1]) }

        context '#setup_schedule' do
          include_context 'mocked abilities', :cannot, :schedule_request, Request
          specify { get :setup_schedule, id: request1, activity_id: activity }
        end

        context '#commit_schedule' do
          include_context 'mocked abilities', :cannot, :schedule_request, Request
          specify { put :commit_schedule, id: request1, activity_id: activity }
        end
      end

      context '#create_consolidated' do
        include_context 'mocked abilities', :cannot, :consolidate_request, Request
        specify { post :create_consolidated }
      end
    end
  end

  it "#index" do
    get :index
    response.should redirect_to(request_dashboard_path)
  end

  context "#application_environment_options" do
    it "renders nothing" do
      get :application_environment_options
      response.should render_template(:nothing => true)
    end

    it "assigns found apps to @apps" do
      @env = create(:environment)
      @app_env = create(:application_environment, :app => @app, :environment => @env)
      get :application_environment_options, {:app_ids => [@app.id]}
      expect(assigns(:apps)).to include(@app)
    end
  end

  context "#application_process_options" do
    it "renders nothing" do
      get :application_process_options
      response.should render_template(:nothing => true)
    end

    it "returns app bussines processes" do
      @bussines_process = create(:business_process, :apps => [@app])
      get :application_process_options, {:app_ids => [@app.id]}
      response.body.should include("#{@bussines_process.id}")
    end
  end

  context "environment_deployment_window_options" do
    it "renders nothing" do
      pending 'ActionController::RoutingError'
      DeploymentWindow::Series.delete_all
      get :environment_deployment_window_options
      response.should render_template(:nothing => true)
    end

    it "returns deployment windows" do
      pending "DeploymentWindows not implemented yet"
      @env = create(:environment)
      get :environment_deployment_window_options, {:request => {:environment_id => @env.id}}
      response.body.should include("#{@deployment_window.id}")
    end
  end

  it "#status" do
    @command = ""
    post :status, {:command => @command}
    @parsed_body = JSON.parse(response.body)
    @parsed_body["payload"].should == Interrogator.new(@command).respond
  end

  context "#set_unset_auto_refresh" do
    it "turns on" do
      get :set_unset_auto_refresh, {:auto_refresh => "1",
                                    :id => request_id}
      session[:request_auto_refresh].should eql(["#{request_id}"])
      response.body.should include('true')
    end

    it "turns off" do
      get :set_unset_auto_refresh, {:id => request_id}
      session[:request_auto_refresh].should_not eql(["#{request_id}"])
      response.body.should include('false')
    end
  end

  it "#get_status" do
    get :get_status, {:id => request_id}
    response.body.should include("#{request1.aasm.current_state}")
  end

  context "#needs_update" do
    it "renders nothing when last_check nil" do
      get :needs_update, {:id => request_id}
      response.body.should include("false")
    end

    it "renders noting when last activity by current user" do
      session["last_update_check"] = Time.now - 1.week
      Request.stub(:find).and_return(request1)
      request1.stub(:last_activity_at).and_return(Time.now)
      request1.stub(:last_activity_by).and_return(@user.id)
      get :needs_update, {:id => request1.id}
      response.body.should include("false")
    end

    it "renders text aasm_state" do
      session["last_update_check"] = Time.now - 1.week
      Request.stub(:find).and_return(request1)
      request1.stub(:last_activity_at).and_return(Time.now)
      request1.stub(:last_activity_by).and_return(@user.id+1)
      get :needs_update, {:id => request_id}
      response.body.should include("#{request1.aasm.current_state}")
    end
  end

  context "#show" do
    let(:valid_params) { { id: request_id } }

    it "renders partial" do
      xhr :get, :show, valid_params
      response.should render_template(:partial => 'requests/_request_name_tab')
    end

    it "renders template request_pdf" do
      get :show, valid_params.merge(export: true)
      response.should render_template("requests/request_pdf")
    end

    context 'pdf' do
      let(:valid_params) { { :id => request_id,
                             :export => true,
                             :format => "pdf" } }

      it "renders pdf" do
        get :show, valid_params
        response.should render_template("requests/request_pdf")
      end

      it_behaves_like 'authorizable', controller_action: :show,
                                      ability_action: :export_as_pdf,
                                      subject: Request do
        before { ActionController::Base.any_instance.stub(:make_and_send_pdf) }
        let(:params) { { id: request_id, format: 'pdf' } }
      end
    end

    it "render temlate edit" do
      get :show, valid_params.merge(export: false)
      response.should render_template('requests/edit')
    end

    context 'xml' do
      before { RequestsController.any_instance.stub(:edit) }

      it_behaves_like 'authorizable', controller_action: :show,
                                      ability_action: :export_as_xml,
                                      subject: Request do
        let(:params) { { id: request_id, format: 'xml' } }
      end
    end

    it_behaves_like 'authorizable', controller_action: :show,
                                    ability_action: :inspect,
                                    subject: Request,
                                    type: :xhr do
      let(:params) { { id: request_id } }
    end

    context 'there are requests in created state owned by user' do
      it 'does not allow to show such requests when user does not have permission' do
        user = create :user, :with_role_and_group
        TestPermissionGranter.new(user.groups.first.roles.first.permissions) << 'Inspect Request'
        sign_in user
        request_in_created_state = create :request, aasm_state: 'created', owner_id: user.id

        get :show, id: request_in_created_state.number

        expect(response).to redirect_to(root_path)
      end

      it 'allows to show such requests when user has permission' do
        user = create :user, :with_role_and_group
        TestPermissionGranter.new(user.groups.first.roles.first.permissions) << 'Inspect Request' << 'View created Requests list'
        sign_in user
        request_in_created_state = create :request, aasm_state: 'created', owner_id: user.id

        get :show, id: request_in_created_state.number

        expect(response).to be_ok
      end
    end
  end

  it "#new" do
    @activity = create(:activity)
    get :new, {:activity_id => @activity.id,
               :activity_app_id => @app.id}
    response.should render_template('new')
  end

  it "#load_request_steps" do
    pending "missing template"
    get :load_request_steps, {:id => request_id}
  end

  describe "#edit" do
    it 'renderes edit template' do
      @request_template = create(:request_template, :request => request1)
      get :edit, {:id => request_id}
      request1.plan_member.should_not be_nil
      request1.uploads.should_not be_nil
      response.should render_template('edit')
    end

    context 'there are requests in created state owned by user' do
      it 'does not allow to edit such requests when user does not have permission' do
        user = create :user, :with_role_and_group
        TestPermissionGranter.new(user.groups.first.roles.first.permissions) << 'Inspect Request'
        sign_in user
        request_in_created_state = create :request, aasm_state: 'created', owner_id: user.id

        get :edit, id: request_in_created_state.number

        expect(response).to redirect_to(root_path)
      end

      it 'allows to edit such requests when user has permission' do
        user = create :user, :with_role_and_group
        TestPermissionGranter.new(user.groups.first.roles.first.permissions) << 'Inspect Request' << 'View created Requests list'
        sign_in user
        request_in_created_state = create :request, aasm_state: 'created', owner_id: user.id

        get :edit, id: request_in_created_state.number

        expect(response).to be_ok
      end
    end
  end

  describe "#modify_details" do
    let(:valid_params) { { id: request_id, plan_id: create(:plan).id } }

    it do
      get :modify_details, valid_params
      response.should render_template("modify_details")
    end

    it_behaves_like 'authorizable', controller_action: :modify_details,
                                    ability_action: :edit,
                                    subject: Request do
                                      let(:params) { valid_params }
                                    end
  end

  describe "#notification_options" do
    let(:valid_params) { { id: request_id } }
    it do
      get :notification_options, valid_params
      response.should render_template("notification_options")
    end

    it_behaves_like 'authorizable', controller_action: :notification_options,
                                    ability_action: :change_notification_options,
                                    subject: Request do
      let(:params) { valid_params }
    end
  end


  describe "#notification_options" do
    it "only contains an active group" do
      active_group = create(:group, active: true)
      inactive_group = create(:group, active: false)
      get :notification_options, { id: request_id }

      expect(assigns(:groups)).to include(active_group)
      expect(assigns(:groups)).not_to include(inactive_group)
    end
  end

  context "#create" do
    before(:each) do
      @activity = create(:activity)
      @request_params = {:name => "Test Request1",
                         :deployment_coordinator_id => @user.id,
                         :requestor_id => @user.id,
                         :environment_id => @env.id,
                         :activity_id => @activity.id,
                         :package_content_ids => [@package_content.id],
                         :additional_email_addresses => DEFAULT_SUPPORT_EMAIL_ADDRESS,
                         :updated_at => '2008-10-27 18:27:12 Z',
                         :notify_on_request_start => false,
                         :notify_on_step_complete => false,
                         :notify_on_step_start => false,
                         :business_process_id => 1,
                         :notify_on_request_complete => false,
                         :created_at => Time.now,
                         :notes_attributes => {"0" => {:content => ''}}}
    end

    it "creates request from promotion" do
      pending "undefined method `+' for nil:NilClass"
      @target_env = create(:environment)
      @sourse_env = create(:environment)
      @request_template = create(:request_template)
      expect{post :create, {:from_promotion => true,
                            :request => @request_params,
                            :request_template_id => @request_template.id,
                            :target_env => @target_env.id,
                            :sourse_env => @sourse_env.id,
                            :package_content_ids => [@package_content.id],
                            :app_id => @app.id}
            }.to change(Request, :count).by(1)
      response.code.should eql("302")
    end

    xit "returns flash 'successfully' and redirect" do
      @upload = create(:upload)
      expect{post :create, {:from_promotion => false,
                            :request => @request_params}
            }.to change(Request, :count).by(1)
      flash[:success].should include("successfully")
      response.code.should eql("302")
    end

    it "render action new" do
      post :create, {:request => {:owner => nil,
                                  :notes_attributes => {"0" => {:content => ''}},
                                  :environment_id => @env.id}}
      response.should render_template('new')
    end

    context 'with_multi_environments' do
      let(:env2) { create(:environment) }
      let(:request_params) {{ name: 'Test Request1',
                              requestor_id: @user.id,
                              app_id: @app.id,
                              environment_ids: "#{@env.id},#{env2.id}" }}
      let!(:app_env) { create(:application_environment, :app => @app, :environment => env2) }
      let!(:assigned_env) { AssignedEnvironment.create!(:environment_id => env2.id,
                                                        :assigned_app_id => @app.assigned_apps.first.id,
                                                        :role => @user.roles.first) }

      it 'creates 2 requests on different environments' do
        expect{post :create, { from_promotion: false,
                               request: request_params }
        }.to change(Request, :count).by(2)
      end

      it 'redirects to first request edit page' do
        post :create, { from_promotion: false,
                        request: request_params }
        request_to_redirect = Request.all.first
        expect(response).to redirect_to edit_request_path(request_to_redirect.number)
      end
    end
  end

  describe "#update_notes" do
    let(:valid_params) { { id: request_id,
                           update_notes_only: true,
                           request: { notes: "Content" },
                           format: "js"} }

    it 'creates new note and renders notes update template' do
      expect { post :update_notes, valid_params }.to change(Note, :count).by(1)
      response.should render_template('requests/request_notes_update')
    end

    it_behaves_like 'authorizable', controller_action: :update_notes,
                                    ability_action: :update_notes,
                                    subject: Request,
                                    http_method: :post do
                                      let(:params) { valid_params }
                                    end
  end

  context "#update" do
    before(:each) do
      @group = create(:group)
    end

    let(:valid_params) { { :id                              => request_id,
                           :selected_request_environment_id => "",
                           :old_environment_id              => "",
                           :old_app_ids                     => "",
                           :user_email_recipients           => [@user.id],
                           :group_email_recipients          => [@group.id],
                           :request                         => { :app_ids => [@app.id],
                                                                 :package_content_ids => [@package_content.id],
                                                                 :environment_id      => @env.id } } }

    it "ajax redirects to request path" do
      xhr :put, :update, valid_params.merge( editing_details: '1', updating_notification_options: true )
                                     .tap { |h| h[:request].merge! name: 'Name_changed', app_ids: [] }
      request1.reload
      request1.name.should eql('Name_changed')
      request1.apps.should_not include(@app)
      request1.environment.should eql(@env)
      response.should render_template('misc/redirect')
    end

    it "redirects to request path" do
      pending 'Java::JavaLang::NullPointerException'
      @upload = create(:upload)
      request1.uploads << @upload
      put :update, valid_params.merge( old_environment_id: @env.id, upload_for_deletion: @upload.id )
                               .tap { |h| h[:request].merge! app_id: @app.id }
      flash[:success].should include('successfully')
      request1.reload
      request1.uploads.should_not include(@upload)
      response.should redirect_to(request1)
    end


    it "shows validation errors" do
      Request.stub(:find_by_number).and_return(request1)
      request1.stub(:save).and_return(false)
      xhr :put, :update, valid_params
      response.should render_template('misc/error_messages_for')
    end

    it "renders action edit" do
      Request.stub(:find_by_number).and_return(request1)
      request1.stub(:save).and_return(false)
      put :update, valid_params
      flash[:failure].should include('not updated')
      response.should render_template('edit')
    end

    context 'there are requests in created state owned by user' do
      it 'does not allow to update such requests when user does not have permission' do
        user = create :user, :with_role_and_group
        TestPermissionGranter.new(user.groups.first.roles.first.permissions) << 'Modify Requests Details'
        sign_in user
        request_in_created_state = create :request, aasm_state: 'created', owner_id: user.id

        put :update, valid_params.merge({ id: request_in_created_state.number })

        expect(response).to redirect_to(root_path)
      end

      it 'allows to update such requests when user has permission' do
        user = create :user, :with_role_and_group
        TestPermissionGranter.new(user.groups.first.roles.first.permissions) << 'Modify Requests Details' << 'View created Requests list'
        sign_in user
        request_in_created_state = create :request, aasm_state: 'created', owner_id: user.id

        put :update, valid_params.merge({ id: request_in_created_state.number })

        expect(response).to be_ok
      end
    end

    it_behaves_like 'authorizable', controller_action: :update,
                                    ability_action: :edit,
                                    subject: Request,
                                    http_method: :put do
      let(:params) { valid_params }
    end

    it_behaves_like 'authorizable', controller_action: :update,
                                    ability_action: :apply_template,
                                    subject: Request,
                                    http_method: :put do
      let(:params) { valid_params }
    end

    it_behaves_like 'authorizable', controller_action: :update,
                                    ability_action: :change_notification_options,
                                    subject: Request,
                                    http_method: :put do
      let(:params) { valid_params }
    end

    it_behaves_like 'authorizable', controller_action: :update,
                                    ability_action: :edit_component_versions,
                                    subject: Request,
                                    http_method: :put do
      let(:params) { valid_params }
    end
  end

  describe "#destroy" do
    let!(:valid_params) { { id: request_id } }

    it do
      expect{delete :destroy, valid_params
            }.to change(Request, :count).by(-1)
      response.should redirect_to(request_dashboard_path)
    end

    it_behaves_like 'authorizable', controller_action: :destroy,
                                    ability_action: :delete,
                                    subject: Request,
                                    http_method: :delete do
      let(:params) { valid_params }
    end
  end

  context "#reorder_steps" do
    it "renders template reorder steps" do
      get :reorder_steps, {:id => request_id}
      response.should render_template('reorder_steps')
    end

    it "returns flash error" do
      get :reorder_steps, {:id => '-1'}
      flash[:error].should include('does not exist')
      response.should redirect_to(root_path)
    end

    it_behaves_like 'authorizable', controller_action: :reorder_steps,
                                    ability_action: :reorder_steps,
                                    subject: Request do
                                      let(:params) { { id: request_id } }
                                    end
  end

  context "#update_state" do
    before(:each) do
      @step = create(:step, :request => request1)
    end

    specify "plan" do
      get :update_state, {:id => request_id,
                          :transition => 'plan'}
      request1.reload
      request1.aasm_state.should eql("planned")
    end

    specify "start" do
      request1.plan_it!
      get :update_state, {:id => request_id,
                          :transition => 'start'}
      request1.reload
      request1.aasm_state.should eql("started")
    end

    specify "hold" do
      request1.plan_it!
      request1.start_request!
      get :update_state, {:id => request_id,
                          :transition => 'hold'}
      request1.reload
      request1.aasm_state.should eql("hold")
    end

    specify "problem" do
      request1.plan_it!
      request1.start_request!
      get :update_state, {:id => request_id,
                          :transition => 'problem'}
      request1.reload
      request1.aasm_state.should eql("problem")
    end

    specify "resolve" do
      request1.plan_it!
      request1.start_request!
      request1.problem_encountered!
      get :update_state, {:id => request_id,
                          :transition => 'resolve'}
      request1.reload
      request1.aasm_state.should eql("started")
    end

    specify "cancel" do
      pending "TypeError: incompatible marshal file format (can't be read)"
      request1.plan_it!
      request1.start_request!
      get :update_state, {:id => request_id,
                          :transition => 'cancel'}
      request1.reload
      request1.aasm_state.should eql("cancelled")
    end

    specify "reopen" do
      pending "TypeError: incompatible marshal file format (can't be read)"
      @step.delete
      request1.plan_it!
      request1.start_request!
      get :update_state, {:id => request_id,
                          :transition => 'reopen'}
      request1.reload
      request1.aasm_state.should eql("planned")
    end

    it "returns error" do
      pending "this won't return specified error 'cause flash[:error] is replaced with [] and then deleted"
      Request.stub(:find_by_number).and_return(request1)
      request1.stub(:is_available_for_current_user?).and_return(false)
      get :update_state, {:id => request_id,
                          :transition => 'start'}
      flash[:error].should include('Deployer or Executor to start a request')
    end
  end

  it "#notes_by_step" do
    get :notes_by_step, {:id => request_id}
    response.should render_template(:partial => 'requests/_notes_by_step')
  end

  it "#notes_by_user" do
    get :notes_by_user, {:id => request_id}
    response.should render_template(:partial => 'requests/_notes_by_user')
  end

  it "#notes_by_time" do
    get :notes_by_time, {:id => request_id}
    response.should render_template(:partial => 'requests/_notes_by_time')
  end

  context "#choose_environment_for_template" do
    before(:each) do
      @request_template = create(:request_template, :request => request1)
    end

    it "renders template" do
      RequestTemplate.stub(:find).and_return(double('request_template', request: []))
      controller.stub(:prepare_plan_data).and_return(true)
      get :choose_environment_for_template, {:request_template_id => '1'}
      response.should render_template("requests/choose_environment_for_template")
    end

    it "render nothing" do
      RequestTemplate.stub(:find).and_return(@request_template)
      @request_template.stub(:request).and_return(request1)
      request1.stub(:apps).and_return([])
      get :choose_environment_for_template, {:request_template_id => @request_template.id}
      response.body.should eql("")
    end
  end

  context "#create_from_template" do
    it "redirects to edit request path" do
      @request_template = create(:request_template, :request => request1)
      post :create_from_template, {:request_template_id => @request_template.id, :format => 'js'}
      response.should render_template('create_from_template')
    end

    it "returns flash error 'not specified'" do
      RequestTemplate.stub(:find).and_return(stub_model(RequestTemplate, instantiate_request: stub_model(Request, closed?: true)))
      request.env["HTTP_REFERER"] = '/index'
      post :create_from_template, {:request_template_id => ''}
      flash[:error].should include('not specified')
    end

    it "returns flash error 'not found'" do
      RequestTemplate.stub(:find).and_raise(ActiveRecord::RecordNotFound)

      request.env["HTTP_REFERER"] = '/index'
      post :create_from_template, {:request_template_id => -1}
      flash[:error].should include('not found')
      response.should redirect_to('/index')
    end

    it_behaves_like 'authorizable', controller_action: :create_from_template,
                                    ability_action: :create,
                                    subject: Request do
                                      before { request.env["HTTP_REFERER"] = '/index' }
    end

    context 'with_multi_environments' do
      let(:env2) { create(:environment) }
      let(:request_params) {{ name: 'Test Request1',
                              requestor_id: @user.id,
                              app_id: @app.id,
                              environment_ids: "#{@env.id},#{env2.id}" }}
      let!(:app_env) { create(:application_environment, :app => @app, :environment => env2) }
      let!(:assigned_env) { AssignedEnvironment.create!(:environment_id => env2.id,
                                                        :assigned_app_id => @app.assigned_apps.first.id,
                                                        :role => @user.roles.first) }
      let!(:request_template) { create(:request_template, :request => request1) }

      it 'creates 2 requests on different environments' do
        expect{post :create_from_template, { request_template_id: request_template.id,
                                             request: request_params}
        }.to change(Request, :count).by(2)
      end

      it 'redirects to first request edit page' do
        post :create_from_template, { request_template_id: request_template.id,
                                      request: request_params}
        request_to_redirect = Request.last(2).first
        expect(response).to redirect_to request_path(request_to_redirect.number)
      end
    end
  end

  it "#activity_by_time" do
    get :activity_by_time, {:id => request_id}
    response.should render_template(:partial => 'requests/_activity_by_time')
  end

  it "#activity_by_user" do
    get :activity_by_user, {:id => request_id}
    response.should render_template(:partial => 'requests/_activity_by_user')
  end

  context "#activity_by_step" do
    specify "with step" do
      @step = create(:step, :request => request1)
      get :activity_by_step, {:id => request_id}
      response.should render_template(:partial => 'requests/_activity_by_step')
    end

    specify "without steps" do
      get :activity_by_step, {:id => request_id}
      response.should render_template(:partial => 'requests/_activity_by_step')
    end
  end

  it "#add_category" do
    @category = create(:category)
    post :add_category, {:id => request_id, :transition => 'problem'}
    assigns(:categories).should include(@category)
    response.should render_template("add_category")
  end

  context "#add_message" do
    it "returns message started" do
      get :add_message, {:id => request_id, :transition => 'start'}
      assigns(:message).subject.should include('started')
      response.should render_template('add_message')
    end

    it "returns message put on hold" do
      get :add_message, {:id => request_id, :transition => 'hold'}
      assigns(:message).subject.should include('put on hold')
    end
  end

  context "#send_message" do
    it "success" do
      put :send_message, {:id => request_id,
                          :transition => 'start',
                          :message => {:body => "Text",
                                       :sender_id => @user.id}}
      flash[:success].should eql("Message Sent")
      response.body.should include('start')
    end

    it "fails" do
      put :send_message, {:id => request_id, :transition => 'start'}
      response.body.should include('error')
    end
  end

  context "#add_procedure" do
    it "gets step count of procudure" do
      procedure = create(:procedure, :with_steps, apps: [@app])
      post :add_procedure, {:id => request_id}
      expect(assigns(:steps_count)[procedure.id]).to eql(procedure.steps.count)
    end

    it "renders add_procedure template" do
      post :add_procedure, {:id => request_id}
      response.should render_template("add_procedure")
    end
  end

  it "#add_new_procedure" do
    post :add_new_procedure, {:id => request_id, :format => 'js'}
    response.should render_template('add_new_procedure')
  end

  it "#setup_schedule" do
    @activity = create(:activity)
    @activity.requests << request1
    get :setup_schedule, {:id => request_id, :activity_id => @activity.id}
    response.should render_template('setup_schedule')
  end

  it "#commit_schedule" do
    @activity = create(:activity)
    @activity.requests << request1
    expect{put :commit_schedule, {:id => request_id,
                                  :activity_id => @activity.id,
                                  :schedule => {:hour => 10,
                                                :minute => 15,
                                                :meridian => 'AM'}}
          }.to change(RequestTemplate, :count).by(1)
    response.should render_template(@activity)
  end

  describe '#create_consolidated' do
    it "redirects to edit path" do
      req_id = request1.id
      expect{post :create_consolidated, {:request_ids => [req_id]}
            }.to change(Request, :count).by(1)
      response.code.should eql('302')
    end

    it "redirects to root" do
      post :create_consolidated, {:request_ids => nil}
      flash[:error].should eql('You cannot Consolidate requests with Application that has strict plan control')
      response.should redirect_to(root_path)
    end

    it_behaves_like 'authorizable', controller_action: :create_consolidated,
                                    ability_action: :create,
                                    subject: Request
  end

  context "#server_properties_for_step" do
    before(:each) do
      create_installed_component
      AssignedEnvironment.create!(:environment_id => @my_env.id, :assigned_app_id => @my_app.assigned_apps.first.id, :role => @user.roles.first)
      @new_request = create(:request, :apps => [@my_app], :environment_id => @my_env.id)
      @server = create(:server)
      @installed_component.servers << @server
      @new_request.environment_id = @my_env.id
      @my_env.requests << @new_request
      @new_request.save
      @new_request_id = @new_request.id   + GlobalSettings[:base_request_number]
    end

    specify "with steps" do
      @step = create(:step, :request => @new_request,
                     :component => @component)
      get :server_properties_for_step, {:id => @new_request_id,
                                        :step_id => @step.id,
                                        :component_id => @component.id}
      response.should render_template(:partial => 'steps/_server_properties')
    end

    specify "without steps" do
      get :server_properties_for_step, {:id => @new_request_id,
                                        :component_id => @component.id}
      response.should render_template(:partial => 'steps/_server_properties')
    end
  end

  context "#component_versions" do
    context "#post" do
      before(:each) do
        create_installed_component
        @step = create(:step, :request => request1, :component => @component)
      end

      specify "with limit versions" do
        @version_tag = create(:version_tag,
                              :component => @component,
                              :app => @app,
                              :application_environment => @app_env,
                              :installed_component => @installed_component)
        GlobalSettings.stub(:limit_versions?).and_return(true)
        post :component_versions, {:id => request_id,
                                   :new_version => {@step.id => @version_tag.id}}
        @step.reload
        @step.component_version.should eql(@version_tag.name)
        @step.version_tag_id.should eql(@version_tag.id)
      end

      specify "without limit versions" do
        GlobalSettings.stub(:limit_versions?).and_return(false)
        post :component_versions, {:id => request_id,
                                   :new_version => {@step.id => 'changed'}}
        @step.reload
        @step.component_version.should eql('changed')
      end
    end

    it "renders partial" do
      get :component_versions, {:id => request_id}
      response.should render_template('component_versions')
    end

    it_behaves_like 'authorizable', controller_action: :component_versions,
                                    ability_action: :edit_component_versions,
                                    subject: Request do
                                      let(:params) { { id: request_id } }
                                    end
  end

  context "#summary" do
    it "renders action with xhr" do
      xhr :get, :summary, {:id => request_id}
      response.should render_template('requests/summary')
    end

    it "renders template request_pdf" do
      get :summary, {:id => request_id,
                     :export => true}
      response.should render_template("requests/summary_pdf")
    end

    it "renders pdf" do
      get :summary, {:id => request_id,
                     :format => "pdf",
                     :export => true}
      response.should render_template("requests/summary_pdf")
    end

    it_behaves_like 'authorizable', controller_action: :summary,
                                    ability_action: :view_coordination_summary,
                                    subject: Request do
                                      let(:params) { { id: request_id } }
                                    end
  end

  context "#activity_summary" do
    it "returns planing activity" do
      request1.plan_it!
      xhr :get, :activity_summary, {:id => request_id}
      response.should render_template('activity_summary')
    end

    it "returns blank hash" do
      get :activity_summary, {:id => request_id,
                              :export => true}
      response.should render_template('requests/summary_pdf')
    end

    it "returns activity summary pdf" do
      get :activity_summary, {:id => request_id,
                              :format => "pdf",
                              :export => true}
      response.should render_template('requests/activity_summary_pdf')
    end

    it_behaves_like 'authorizable', controller_action: :activity_summary,
                                    ability_action: :view_activity_summary,
                                    subject: Request do
                                      let(:params) { { id: request_id } }
                                    end
  end

  context "#property_summary" do
    let(:valid_params) { { id: request_id } }
    specify "xhr" do
      xhr :get, :property_summary, valid_params
      response.should render_template("property_summary", :layout => false)
    end

    specify "get" do
      get :property_summary, valid_params
      response.should render_template("property_summary")
    end

    it_behaves_like 'authorizable', controller_action: :property_summary,
                                    ability_action: :view_property_summary,
                                    subject: Request do
      let(:params) { valid_params }
    end
  end

  it "#env_visibility" do
    get :env_visibility, {:id => request_id,
                          :env_id => @env.id,
                          :checked_status => true,
                          :format => 'js'}
    response.should render_template('requests/env_visibility')
  end

  it "#request_modification" do
    get :request_modification, {:id => request_id}
    response.should render_template('request_modification')
  end

  context "#bulk_destroy" do
    it "destroys request" do
      req_id = request1.id
      expect { delete :bulk_destroy, {:request_ids => [req_id]} }.to change(Request, :count).by(-1)
    end

    it "renders partial" do
      xhr :get, :bulk_destroy
      response.should render_template(:partial => 'requests/_bulk_delete_requests')
    end

    it_behaves_like 'authorizable', controller_action: :bulk_destroy,
                                    ability_action: :delete,
                                    subject: Request
  end

  context "#modify_request" do
    before(:each) do
      User.stub(:find).and_return(@user)
    end

    it "renders template" do
      get :modify_request, {:request_id => request_id}
      response.should render_template("requests/modify_details")
    end

    it "renders text 'invalid id'" do
      get :modify_request, {:request_id => "-1"}
      response.body.should include("Invalid request id.")
    end

    it "renders text 'request deleted'" do
      request1.aasm_state = 'deleted'
      request1.save
      get :modify_request, {:request_id => request_id}
      response.body.should include("has been deleted")
    end
  end

  context "#apply_template" do
    let(:valid_params) { { id: request_id,
                           plan_id: @plan.id,
                           plan_stage_id: @plan_stage.id } }

    before(:each) do
      @plan_template = create(:plan_template)
      @plan = create(:plan, :plan_template => @plan_template)
      @plan_stage = create(:plan_stage, :plan_template => @plan_template)
    end

    it "renders template" do
      get :apply_template, valid_params
      response.should render_template('apply_template')
    end

    it "redirect to request_path" do
      request1.plan_it!
      get :apply_template, valid_params
      response.should redirect_to(request_path(request1))
    end

    it_behaves_like 'authorizable', controller_action: :apply_template,
                                    ability_action: :apply_template,
                                    subject: Request do
                                      let(:params) { valid_params }
                                    end
  end

  it "#package_template_items_for_steps" do
    @package_template = create(:package_template, :app => @app, :name => 'PT1', :version => '2')
    get :package_template_items_for_steps, {:package_template_id => @package_template.id}
    response.should render_template(:partial => "steps/_app_package_template_items")
  end

  it "#template_item_properties" do
    @package_template = create(:package_template, :app => @app, :name => 'PT1', :version => '2')
    @package_template_item1 = create(:package_template_item,
                                     :package_template => @package_template)
    @step = create(:step, :request => request1)
    get :template_item_properties, {:template_item_id => @package_template_item1.id,
                                    :step_id => @step}
    response.should render_template(:partial => "steps/_package_template_item_properties")
  end

  it "#change_status" do
    pending "TypeError: incompatible marshal file format (can't be read)"
    @plan_template = create(:plan_template)
    @plan = create(:plan, :plan_template => @plan_template)
    get :change_status, {:id => request_id, :plan_id => @plan.id}
    response.should redirect_to(plans_path+ "#lifecyle#{@plan.id}")
    request1.reload
    request1.aasm_state.should eql('complete')
  end

  it "#update_request_info" do
    get :update_request_info, {:id => request1.id, :format => 'js'}
    response.should render_template('update_request_info')
  end

  it "#deleted_requests" do
    request1.aasm_state = 'deleted'
    request1.save
    xhr :get, :deleted_requests
    assigns(:deleted_requests).should include(request1)
    response.should render_template(:partial => "requests/_custom_list")
  end

  context "#paste_steps" do
    let(:valid_params) { { id: request_id } }

    it "returns flash 'bad request or post data'" do
      get :paste_steps, valid_params
      flash[:error].should include('Bad request or post data')
      response.should render_template('paste_steps', :layout => false)
    end

    it "success" do
      post :paste_steps, valid_params.merge(paste_data: 'name,description\t
                                                         Step1,Description1\t
                                                         Step2,Description2\t')
      flash[:success].should include('Success')
    end

    it "fails" do
      post :paste_steps, valid_params.merge(paste_data: 'created:Step_name')
      flash[:error].should include('Inconsistent titles and data')
      response.should redirect_to(request_path(request1))
    end

    it_behaves_like 'authorizable', controller_action: :paste_steps,
                                    ability_action: :import_steps,
                                    subject: Request do
                                      let(:params) { valid_params }
                                    end
  end

  context "export_xml" do
    let(:valid_params) { { id: request_id } }

    it "returns flash 'export cannot be created'" do
      get :export_xml, valid_params
      flash[:error].should include('export cannot be created')
      response.should redirect_to(request_path(request1))
    end

    it "sends data" do
      get :export_xml, valid_params.merge(send_inline_xml: true)
      response.body.should include("#{request1.name}")
    end

    it_behaves_like 'authorizable', controller_action: :export_xml,
                                    ability_action: :export_as_xml,
                                    subject: Request do
                                      let(:params) { valid_params }
                                    end
  end

  describe "#import_xml" do
    it do
      get :import_xml
      response.should render_template('import_xml')
    end

    it_behaves_like 'authorizable', controller_action: :import_xml,
                                    ability_action: :import,
                                    subject: Request
  end

  it "#all_notes_for_request" do
    get :all_notes_for_request, {:id => request_id}
    response.should render_template(:partial => 'requests/_all_notes_for_request')
  end

  context "#import" do
    it "returns flash error 'select file to import' and redirect" do
      post :import
      flash[:error].should include('select the file')
      response.should redirect_to(request_dashboard_path)
    end

    it "returns flash error 'file should be in XML'" do
      pending "No valid data for import"
      request.env['CONTENT_TYPE'] = 'text/xml'
      post :import, {"request"=> {:filename => '\1055 (1).xml'}}
      flash[:error].should include('should be in XML format')
    end

    it "returns flash error 'Request is not imported'" do
      pending "No valid data for import"
    end

    it "success" do
      pending "No valid data for import"
    end

    it "returns flash error 'Argument Error'" do
      pending "No valid data for import"
    end

    it_behaves_like 'authorizable', controller_action: :import_xml,
                                    ability_action: :import,
                                    subject: Request,
                                    http_method: :post
  end

  describe '#schedule_from_event' do
    it_behaves_like 'authorizable', controller_action: :schedule_from_event,
                                    ability_action: :create,
                                    subject: Request do
                                      let(:params) { { id: create(:request).id,
                                                       event_id: create(:deployment_window_event).id } }
                                    end
  end

  describe '#create_from_event' do
    before do
      RequestsController.any_instance.stub(:reformat_dates_for_save).and_return({ request: {} })
    end

    it_behaves_like 'authorizable', controller_action: :create_from_event,
                                    ability_action: :create,
                                    subject: Request do
                                      let(:params) { { request: attributes_for(:request) } }
                                    end
  end

  describe '#new_clone' do
    before do
      Request.stub_chain(:extant, :find_by_number).and_return(build(:request))
    end

    it_behaves_like 'authorizable', controller_action: :new_clone,
                                    ability_action: :clone,
                                    subject: Request do
                                      let(:params) { { id: create(:request).id } }
                                    end
  end

  describe '#create_clone' do
    before do
      Request.stub_chain(:extant, :find_by_number).and_return(build(:request))
      Request.any_instance.stub(:clone_request_with_dependencies).and_return(create(:request))
      RequestsController.any_instance.stub(:reformat_dates_for_save)
    end

    it_behaves_like 'authorizable', controller_action: :create_clone,
                                    ability_action: :create,
                                    subject: Request do
                                      let(:params) { { id: create(:request).id } }
                                    end
  end

  describe '#multi_environments' do
    let(:app) { create(:app) }
    let(:env2) { create(:environment) }
    let(:request_params) {{ name: 'Test Request1',
                            requestor_id: @user.id,
                            app_id: @app.id,
                            environment_ids: "#{@env.id},#{env2.id}" }}

    context 'render nothing' do
      it 'without app_id' do
        get :multi_environments, { app_id: '', format: 'js' }
        expect{ response }.to be_truthy
      end

      it 'without request_template_id' do
        get :multi_environments, { request_template_id: '', format: 'js' }
        expect{ response }.to be_truthy
      end

      it 'app without visible environments' do
        get :multi_environments, { app_id: app.id, format: 'js' }
        expect{ response }.to be_truthy
      end
    end

    context 'environments present' do
      let(:app) { create(:app) }
      let!(:app_env) { create(:application_environment, :app => app, :environment => env2) }
      let!(:assigned_env) { AssignedEnvironment.create!(:environment_id => env2.id,
                                                        :assigned_app_id => app.assigned_apps.first.id,
                                                        :role => @user.roles.first) }
      let!(:request_template) { create(:request_template, :request => request1) }
      render_views

      it 'returns visible environments' do
        get :multi_environments, { app_id: app.id, format: 'js' }
        expect(assigns(:items)[:all]).to eq([env2])
      end

      it 'returns disabled environments' do
        User.any_instance.stub(:get_disabled_environments).and_return([env2])
        get :multi_environments, { app_id: app.id, format: 'js' }
        expect(assigns(:items)[:disabled_items]).to eq([env2])
      end

      it 'renders inline multiple piker' do
        get :multi_environments, {app_id: app.id, format: 'js'}
        expect{ response }.to render_template('multi_environments')
      end
    end
  end

  describe "GET deployment_window_warning" do
    let(:environments) { create_list(:environment, 5) }
    let(:env_ids) { environments.map(&:id) }
    let(:series) { create(:recurrent_deployment_window_series, name: 'a_window') }
    let(:occurrence) { create(:deployment_window_occurrence, environment_ids: env_ids, series_id: series.id) }
    let(:event) { occurrence.events.first }

    it "renders state usage warning" do
      xhr :get, :deployment_window_warning, event_id: event.id.to_i
      expect(response).to render_template('object_state/_state_usage_warning')
    end

    it "has type deployment_window" do
      xhr :get, :deployment_window_warning, event_id: event.id.to_i
      expect(assigns(:type)).to eql('deployment_window')
    end

    it "includes warning for Events in PENDING state" do
      series.update_attributes(aasm_state: 'pending')
      xhr :get, :deployment_window_warning, event_id: event.id.to_i
      expect(assigns(:warning)).to include(series.warning_state)
    end

    it "includes warning for Events in RETIRED state" do
      series.update_attributes(aasm_state: 'retired')
      xhr :get, :deployment_window_warning, event_id: event.id
      expect(assigns(:warning)).to include(series.warning_state)
    end

    it "includes no warning for Events in RELEASED state" do
      xhr :get, :deployment_window_warning, event_id: event.id
      expect(assigns(:warning)).to be_falsey
    end
  end

  def create_installed_component
    @my_app = create(:app, name: 'The App')
    @my_env = create(:environment)
    @my_app_env = create(:application_environment,
                      :app => @my_app,
                      :environment => @my_env)
    @component = create(:component)
    @app_component = create(:application_component,
                            :app => @my_app,
                            :component => @component)
    @installed_component = create(:installed_component,
                                  :application_environment => @my_app_env,
                                  :application_component => @app_component)
  end
end
