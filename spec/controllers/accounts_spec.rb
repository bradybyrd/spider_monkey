require 'spec_helper'

shared_examples "get scripts", :shared => true do |model, method, factory_model, model_name, setting_enabled, partial|
  before(:each) { GlobalSettings.stub(setting_enabled).and_return(true) }

  it "returns #{model_name}scripts with pagination" do
    model.delete_all
    @scripts = 31.times.collect{create(factory_model)}
    @scripts.sort_by!{|el| el.name}
    get method
    @scripts[0..29].each{|el| assigns(:scripts).should include(el)}
    assigns(:scripts).should_not include(@scripts[30])
  end

  it "returns flash 'No Script'" do
    model.delete_all
    get method
    flash[:error].should include("No #{model_name}Script")
  end

  it "returns #{model_name}scripts with keyword and render partial" do
    @script1 = create(factory_model, :name => 'Dev1')
    @script2 = create(factory_model)
    xhr :get, method, {:key => 'Dev', :clear_filter => '1'}
    assigns(:scripts).should include(@script1)
    assigns(:scripts).should_not include(@script2)
    response.should render_template(:partial => partial) if partial
  end

  it "returns flash 'Automation is disabled'" do
    GlobalSettings.stub(setting_enabled).and_return(false)
    get method
    flash.now[:error].should include("#{model_name}Automation is disabled")
  end
end

describe AccountController, :type => :controller do
  context 'authorization' do
    context 'authorize fails' do
      before {
        GlobalSettings.stub(:automation_enabled?).and_return(true)
        GlobalSettings.stub(:bladelogic_enabled?).and_return(true)
      }
      after { expect(response).to redirect_to root_path }

      context '#automation_scripts' do
        include_context 'mocked abilities', :cannot, :list, :automation
        specify { get :automation_scripts }
      end

      context '#bladelogic' do
        include_context 'mocked abilities', :cannot, :list, :automation
        specify { get :bladelogic }
      end
    end
  end

  context "#settings" do
    it "success" do
      get :settings
      response.should render_template('settings')
    end
  end

  it "#statistics" do
    get :statistics
    response.should render_template('statistics')
  end

  context "#update_settings" do
    it "success" do
      put :update_settings, {:GlobalSettings => {:limit_versions => true}, :format => 'js'}
      flash[:success].should include("successfully")
      response.should render_template('misc/redirect')
    end

    specify "Login" do
      put :update_settings, {:GlobalSettings => {:limit_versions => true,
                                                 :authentication_mode => 0}}
      flash[:success].should include("successfully")
      session[:auth_method].should eql("Login")
    end

    specify "ldap" do
      put :update_settings, {:GlobalSettings => { limit_versions: true,
                                                  authentication_mode: 1,
                                                  ldap_component: 'q',
                                                  ldap_host: 'q'
                                                 }}
      flash[:success].should include("successfully")
      session[:auth_method].should eql("ldap")
    end

    specify "CAS" do
      put :update_settings, {:GlobalSettings => {limit_versions: true,
                                                 authentication_mode: 2,
                                                 cas_server: 'http://expample.com'}}
      flash[:success].should include("successfully")
      session[:auth_method].should eql("CAS")
    end

    it "fails" do
      @hash = {}
      GlobalSettings.stub(:instance).and_return(@hash)
      @hash.stub(:update_attributes).and_return(false)
      put :update_settings, {:GlobalSettings => {}}
      response.should render_template("misc/error_messages_for")
    end
  end

  it "#calendar_preferences" do
    get :calendar_preferences
    response.should render_template('calendar_preferences')
  end

  it_should_behave_like('get scripts', BladelogicScript, :bladelogic, :bladelogic_script, 'Bladelogic ', 'bladelogic_enabled?', 'shared_scripts/bladelogic/_list')
  #it_should_behave_like('get scripts', CapistranoScript, :capistrano, :capistrano_script, 'SSH ', 'capistrano_enabled?', nil)
  #it_should_behave_like('get scripts', HudsonScript, :hudson, :hudson_script, 'Hudson ', 'hudson_enabled?', nil)
  it_should_behave_like('get scripts', Script, :automation_scripts, :general_script, '', 'automation_enabled?', nil)
  it_should_behave_like 'status of objects controller', :general_script, "scripts", :automation_scripts

  context "#automation_monitor" do
    it "returns flash 'No Job Runs' and render template" do
      get :automation_monitor
      flash[:error].should include("No Job Runs")
      response.should render_template('automation_monitor')
    end

    it "returns records with pagination" do
      @job_runs = 31.times.collect{create(:job_run, :started_at => Time.now - 1.weeks,
                                                    :job_type => "Resource Automation")}
      @job_runs.reverse!
      get :automation_monitor
      @job_runs[0..29].each {|el| assigns(:job_runs).should include(el)}
      assigns(:job_runs).should_not include(@job_runs[30])
      JobRun.delete_all
    end
  end

  context "toggle_script_filter" do
    it "returns open filter true" do
      get :toggle_script_filter, {:open_filter => 'true'}
      session[:open_script_filter].should be_truthy
    end

    it "returns open filter false" do
      get :toggle_script_filter
      session[:open_script_filter].should_not be_truthy
    end
  end
end

