require 'spec_helper'

describe ApplicationController, type: :controller do
  controller do
    def test_add_temp_filters
      @filters = add_temp_filters(params[:selected_filters], params[:temp_filters])
      render nothing: true
    end

    def test_remove_temp_filters
      @filters = remove_temp_filters(params[:selected_filters], params[:all_filters])
      render nothing: true
    end

    def test_temp_filters
      @filters = temp_filters
      render nothing: true
    end

    def test_find_plan
      find_plan(params[:id])
      render nothing: true
    end

    def test_set_plan_tab_id
      set_plan_tab_id
      render nothing: true
    end

    def test_host_url
      @url = host_url
      render nothing: true
    end

    def test_current_pagination_page
      @page = current_pagination_page
      render nothing: true
    end

    def test_requires_resource_manager
      @resource_manager = requires_resource_manager
      render nothing: true if @resource_manager == true
    end

    def test_options_from_model_association
      app = params[:id] ? App.find(params[:id]) : nil
      @options = options_from_model_association(app, params[:association], params[:options])
      render nothing: true
    end

    def test_opt_group_options
      app = params[:id] ? App.find(params[:id]) : nil
      @options = opt_group_options!(params[:options], app, params[:css_class])
      render nothing: true
    end

    def test_find_application
      find_application
      render nothing: true
    end

    def test_dashboard_setup
      dashboard_setup
      render nothing: true
    end

    def test_my_data
      my_data
      render nothing: true
    end

    def test_format_response_for_ajax_file_uploads
      format_response_for_ajax_file_uploads
      render nothing: true
    end

    def test_redirect_back_or
      redirect_back_or(params[:path])
    end

    def test_paginate_records
      @records = App.find(params[:records])
      @records = paginate_records(@records, params, params[:per_page])
      render nothing: true
    end

    def test_show_validation_errors
      show_validation_errors(nil)
    end

    def test_ajax_redirect
      ajax_redirect(params[:path])
    end

    def test_show_error_messages
      show_error_messages(nil)
    end

    def test_show_general_error_messages
      show_general_error_messages(nil)
    end

    def test_verify_user_login_status
      verify_user_login_status
      render nothing: true
    end

    def test_my_applications
      my_applications
      render nothing: true
    end

    def test_plan_release_details
      @plan = Plan.find(params[:plan_id])
      plan_release_details
      render nothing: true
    end

    def test_access_denied
      access_denied!
    end

    def test_can_perform_all_action_on_request
      can_perform_all_action_on_request
    end

    def test_put_current_user_into_model
      @result = put_current_user_into_model
      render nothing: true
    end

    def test_current_user_authenticated_via_rpm
      @result = current_user_authenticated_via_rpm?
      render nothing: true
    end

    def test_request_sso_enabled
      request_sso_enabled?
      render nothing: true
    end

    def test_render_404
      render_404
    end

    def test_sign_out_and_redirect
      @user = User.find(params[:id])
      sign_out_and_redirect(@user)
    end
  end

  #################################################

  ######## public

  it '#add_temp_filters' do
    routes.draw { get 'test_add_temp_filters' => 'anonymous#test_add_temp_filters'}
    get :test_add_temp_filters, {selected_filters: {},
                                 temp_filters: {'automation_type' => 'Automation'}}
    assigns(:filters).should eql({'automation_type' => ['Automation']})
  end

  it '#remove_temp_filters' do
    routes.draw { get 'test_remove_temp_filters' => 'anonymous#test_remove_temp_filters'}

    get :test_remove_temp_filters, {selected_filters: {'outbound_requests' => 'Request'},
                                    all_filters: {'automation_type' => 'Automation'}}
    assigns(:filters).should_not include({'automation_type' => 'Automation'})
  end

  it '#temp_filters' do
    routes.draw { get 'test_temp_filters' => 'anonymous#test_temp_filters'}

    get :test_temp_filters, {'for_dashboard' => true}
    assigns(:filters).should include('for_dashboard' => true)
  end

  ######## protected

  context '#find_plan' do
    before(:each) { routes.draw { get 'test_find_plan' => 'anonymous#test_find_plan'} }

    it 'returns plan' do
      @plan = create(:plan)
      get :test_find_plan, {id: @plan.id}
      assigns(:plan).should eql(@plan)
    end

    it 'returns flash' do
      @plan = create(:plan)
      get :test_find_plan, {id: @plan.id+1}
      flash[:notice].should eql('Invalid plan id or plan not found.')
      assigns(:plan).should be_nil
    end
  end

  it '#set_plan_tab_id' do
    routes.draw { get 'test_set_plan_tab_id' => 'anonymous#test_set_plan_tab_id' }

    get :test_set_plan_tab_id, {tab_id: 4}
    assigns(:tab_id).should eql('4')
  end

  it '#host_url' do
    routes.draw { get 'test_host_url' => 'anonymous#test_host_url' }

    get :test_host_url
    assigns(:url).should include("http://#{request.host}")
  end

  it '#current_pagination_page' do
    routes.draw { get 'test_current_pagination_page' => 'anonymous#test_current_pagination_page' }

    get :test_current_pagination_page, {page: 4}
    assigns(:page).should eql('4')
  end

  context '#requires_resource_manager' do
    before(:each) {routes.draw { get 'test_requires_resource_manager' => 'anonymous#test_requires_resource_manager' }}

    it 'redirects' do
      User.any_instance.stub(:resource_manager?).and_return(false)
      User.any_instance.stub(:admin?).and_return(false)

      get :test_requires_resource_manager
      response.should redirect_to(root_path)
    end

    it 'returns true' do
      User.any_instance.stub(:resource_manager?).and_return(true)

      get :test_requires_resource_manager
      assigns(:resource_manager).should be_truthy
    end
  end

  context '#options_from_model_association' do
    before(:each) do
      routes.draw { get 'test_options_from_model_association' => 'anonymous#test_options_from_model_association'}
      @app = create(:app)
      @env = create(:environment)
      @app_env = create(:application_environment, app: @app, environment: @env)
    end

    it 'returns nothing' do
      get :test_options_from_model_association
      assigns(:options).should eql('')
    end

    specify 'with apply method' do
      User.any_instance.stub(:admin?).and_return(false)

      get :test_options_from_model_association, {id: @app.id,
                                                 association: ':application_environments',
                                                 options: {named_scope: ':in_order',
                                                           apply_method: 'application_environments'}}
      assigns(:options).should include("#{@env.name}")
    end

    specify 'without apply method with hash options' do
      get :test_options_from_model_association, {id: @app.id,
                                                 association: :application_environments,
                                                 options: {named_scope: {in_order: 'DESC'}}}
      assigns(:options).should include("#{@env.name}")
    end

    specify 'without apply method' do
      get :test_options_from_model_association, {id: @app.id,
                                                 association: :application_environments,
                                                 options: {named_scope: :in_order}}
      assigns(:options).should include("#{@env.name}")
    end
  end

  it '#opt_group_options!' do
    routes.draw { get 'test_opt_group_options' => 'anonymous#test_opt_group_options' }
    @app = create(:app)

    get :test_opt_group_options, {id: @app.id,
                                  optgroup: true,
                                  css_class: 'class_name',
                                  options: 'options'}
    assigns(:options).should include("#{@app.name}")
    assigns(:options).should include('options')
    assigns(:options).should include('class_name')
  end

  it '#find_application' do
    routes.draw { get 'test_find_application' => 'anonymous#test_find_application' }
    @app = create(:app)

    get :test_find_application, {app_id: @app.id}
    assigns(:app).should eql(@app)
  end

  context '#dashboard_setup' do
    before(:each) do
      routes.draw { get 'test_dashboard_setup' => 'anonymous#test_dashboard_setup' }
      @request1 = create(:request)
    end

    it 'returns request of current user' do
      get :test_dashboard_setup, {show_all: true}
      assigns(:requests).should include(@request1)
    end

    it 'returns extant requests' do
      controller.stub(:user_signed_in?).and_return(false)
      get :test_dashboard_setup, {show_all: true}
      assigns(:requests).should include(@request1)
    end
  end

  it '#my_data' do
    routes.draw { get 'test_my_data' => 'anonymous#test_my_data' }
    @app = create(:app)
    @env = create(:environment)
    @server = create(:server)

    get :test_my_data
    assigns(:my_applications).should include(@app)
    assigns(:my_environments).should include(@env)
    assigns(:my_servers).should include(@server)
  end

  it '#format_response_for_ajax_file_uploads' do
    routes.draw { get 'test_format_response_for_ajax_file_uploads' => 'anonymous#test_format_response_for_ajax_file_uploads' }
    @request.env['CONTENT_TYPE'] = :multipart_form

    get :test_format_response_for_ajax_file_uploads, {_ajax_flag: true}

    response.body.should include('<table>')
  end

  context '#redirect_back_or' do
    before(:each) {routes.draw { get 'test_redirect_back_or' => 'anonymous#test_redirect_back_or' }}

    it 'redirects to back' do
      @request.env['HTTP_REFERER'] = '/index'
      get :test_redirect_back_or, {path: '/'}
      response.should redirect_to('/index')
    end

    it 'redirects to path' do
      get :test_redirect_back_or, {path: '/'}
      response.should redirect_to('/')
    end
  end

  it '#paginate_records' do
    @app_ids = []
    @apps = 11.times.collect{ create(:app) }
    @apps.each { |el| @app_ids << el.id}
    routes.draw { get 'test_paginate_records' => 'anonymous#test_paginate_records' }

    get :test_paginate_records, {records: @app_ids,
                                 per_page: 10,
                                 page: 2}
    @apps[0..9].each { |el| assigns(:records).should_not include(el)}
    assigns(:records).should include(@apps[10])
  end

  it '#show_validation_errors' do
    routes.draw { get 'test_show_validation_errors' => 'anonymous#test_show_validation_errors' }

    get :test_show_validation_errors, {format: 'js'}
    response.should render_template('misc/update_div')
  end

  it '#ajax_redirect' do
    routes.draw { get 'test_ajax_redirect' => 'anonymous#test_ajax_redirect' }

    get :test_ajax_redirect, {path: '/index', format: 'js'}
    response.should render_template('misc/redirect')
  end

  it '#show_error_messages' do
    routes.draw { get 'test_show_error_messages' => 'anonymous#test_show_error_messages' }

    get :test_show_error_messages, {format: 'js'}
    response.should render_template('misc/update_div')
  end

  it '#show_general_error_messages' do
    routes.draw { get 'test_show_general_error_messages' => 'anonymous#test_show_general_error_messages' }

    get :test_show_general_error_messages, {format: 'js'}
    response.should render_template('misc/show_div_update_div')
  end

  context '#verify_user_login_status' do
    before(:each) { routes.draw { get 'test_verify_user_login_status' => 'anonymous#test_verify_user_login_status'} }

    it 'redirects to new_security_question' do
      User.any_instance.stub(:first_time_login?).and_return(true)
      get :test_verify_user_login_status
      response.should redirect_to(new_security_question_path)
    end

    it 'redirects to change_password_users_path' do
      User.any_instance.stub(:is_reset_password?).and_return(true)
      get :test_verify_user_login_status
      response.should redirect_to(change_password_users_path)
    end

    it "logout user when terminate session flag is set" do
      User.any_instance.stub(:terminate_session).and_return(true)
      User.any_instance.stub(:admin?).and_return(false)
      get :test_verify_user_login_status
      response.should redirect_to(logout_path)
    end
  end

  it '#my_applications' do
    ApplicationController::MY_APPLICATION_LIMIT = 2
    apps_limit                                  = ApplicationController::MY_APPLICATION_LIMIT
    apps                                        = create_list(:app, apps_limit + 1).sort_by(&:name)

    routes.draw { get 'test_my_applications' => 'anonymous#test_my_applications'}

    get :test_my_applications
    expect(assigns(:my_applications)).to match_array apps.first(apps_limit)
    expect(assigns(:my_applications)).to_not include apps.last
  end

  context '#plan_release_details' do
    before(:each) do
      routes.draw { get 'test_plan_release_details' => 'anonymous#test_plan_release_details' }
      @plan = create(:plan)
      @plan_template = create(:plan_template)
      @environment_type = create(:environment_type)
      @plan_stage = create(:plan_stage, plan_template: @plan_template,
                                        environment_type: @environment_type)
      @member = create(:plan_member, plan: @plan,
                                     stage: @plan_stage)
      @plan.members << @member
    end

    specify 'with filters' do
      get :test_plan_release_details, {plan_id: @plan.id,
                                       filters: {sort_direction: 'asc'}}
      assigns(:grouped_members)[@plan_stage.id].should include(@member)
    end

    specify 'without filters' do
      get :test_plan_release_details, {plan_id: @plan.id}
      assigns(:grouped_members)[@plan_stage.id].should include(@member)
    end
  end

  it '#access_denied!' do
    MainTabs.stub(:root_path).and_return(root_path)
    routes.draw { get 'test_access_denied' => 'anonymous#test_access_denied' }

    get :test_access_denied
    response.should redirect_to(root_path)
  end

  it '#can_perform_all_action_on_request' do
    routes.draw { post 'test_can_perform_all_action_on_request' => 'anonymous#test_can_perform_all_action_on_request' }
    controller.stub(:can?).and_return(false)
    @request1 = create(:request)
    @request_id = @request1.id + GlobalSettings[:base_request_number]

    post :test_can_perform_all_action_on_request, {id: @request_id}
    flash[:notice].should include('Access Denied')
    response.should redirect_to(@request1)
  end

  it '#put_current_user_into_model' do
    routes.draw { post 'test_put_current_user_into_model' => 'anonymous#test_put_current_user_into_model' }
    session[:auth_method] = 'Login'

    get :test_put_current_user_into_model
    assigns(:result).should be_truthy
  end

  it '#current_user_authenticated_via_rpm?' do
    routes.draw { post 'test_current_user_authenticated_via_rpm' => 'anonymous#test_current_user_authenticated_via_rpm' }
    session[:auth_method] = 'Login'

    get :test_current_user_authenticated_via_rpm
    assigns(:result).should be_truthy
  end

  it '#request_sso_enabled?' do
    routes.draw { post 'test_request_sso_enabled' => 'anonymous#test_request_sso_enabled' }
    @request.env['REMOTE_USER'] = @user

    get :test_request_sso_enabled
    session[:sso_enabled].should be_truthy
  end

  it '#render_404' do
    routes.draw { post 'test_render_404' => 'anonymous#test_render_404' }

    get :test_render_404
    response.should render_template(file: "#{Rails.root}/public/404.html")
  end

  ######## private

  it '#sign_out_and_redirect' do
    routes.draw { post 'test_sign_out_and_redirect' => 'anonymous#test_sign_out_and_redirect'}
    @request.env['REMOTE_USER'] = @user

    get :test_sign_out_and_redirect, {id: @user.id}
    response.should render_template ('sessions/destroy')
  end

end
