require 'spec_helper'

shared_examples 'get scripts', shared: true do |model, method, factory_model, model_name, setting_enabled, partial|
  before(:each) { GlobalSettings.stub(setting_enabled).and_return(true) }

  it "returns #{model_name}scripts with pagination" do
    model.delete_all
    scripts = 31.times.collect{create(factory_model)}
    scripts.sort_by!{|el| el.name}
    get method
    scripts[0..29].each{|el| expect(assigns(:scripts)).to include(el)}
    expect(assigns(:scripts)).to_not include(scripts[30])
  end

  it 'returns flash \'No Script\"'do
    model.delete_all
    get method
    expect(flash[:error]).to include("No #{model_name}Script")
  end

  it "returns #{model_name}scripts with keyword and render partial" do
    script1 = create(factory_model, name: 'Dev1')
    script2 = create(factory_model)
    xhr :get, method, {key: 'Dev', clear_filter: '1'}
    expect(assigns(:scripts)).to include(script1)
    expect(assigns(:scripts)).to_not include(script2)
    expect(response).to render_template(partial: partial) if partial
  end

  it 'returns flash \'Automation is disabled\'' do
    GlobalSettings.stub(setting_enabled).and_return(false)
    get method
    expect(flash.now[:error]).to include("#{model_name}Automation is disabled")
  end
end

describe AccountController, type: :controller do
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

  context '#settings' do
    it 'success' do
      get :settings
      expect(response).to render_template('settings')
    end
  end

  it '#statistics' do
    get :statistics
    expect(response).to render_template('statistics')
  end

  context '#update_settings' do
    it 'success' do
      put :update_settings, { GlobalSettings: { limit_versions: true },
                              format: 'js' }
      expect(flash[:success]).to include('successfully')
      expect(response).to render_template('misc/redirect')
    end

    specify 'Login' do
      put :update_settings, {GlobalSettings: { limit_versions: true,
                                               authentication_mode: 0 }}
      expect(flash[:success]).to include('successfully')
      expect(session[:auth_method]).to eq 'Login'
    end

    specify 'ldap' do
      put :update_settings, {GlobalSettings: { limit_versions: true,
                                               authentication_mode: 1,
                                               ldap_component: 'q',
                                               ldap_host: 'q' }}
      expect(flash[:success]).to include('successfully')
      expect(session[:auth_method]).to eq 'ldap'
    end

    specify 'CAS' do
      put :update_settings, { GlobalSettings: { limit_versions: true,
                                                authentication_mode: 2,
                                                cas_server: 'http://example.com' }}
      expect(flash[:success]).to include('successfully')
      expect(session[:auth_method]).to eq 'CAS'
    end

    it 'fails' do
      hash = {}
      GlobalSettings.stub(:instance).and_return(hash)
      hash.stub(:update_attributes).and_return(false)
      put :update_settings, { GlobalSettings: {} }
      expect(response).to render_template('misc/error_messages_for')
    end
  end

  it '#calendar_preferences' do
    get :calendar_preferences
    expect(response).to render_template('calendar_preferences')
  end

  it_should_behave_like('get scripts', BladelogicScript, :bladelogic, :bladelogic_script, 'Bladelogic ', 'bladelogic_enabled?', 'shared_scripts/bladelogic/_list')
  it_should_behave_like('get scripts', Script, :automation_scripts, :general_script, '', 'automation_enabled?', nil)
  it_should_behave_like('status of objects controller', :general_script, 'scripts', :automation_scripts)

  context '#automation_monitor' do
    it 'returns flash \'No Job Runs\' and render template' do
      get :automation_monitor
      expect(flash[:error]).to include('No Job Runs')
      expect(response).to render_template('automation_monitor')
    end

    it 'returns records with pagination' do
      job_runs = 31.times.collect{create(:job_run,
                                         started_at: Time.now - 1.weeks,
                                         job_type: 'Resource Automation')}
      job_runs.reverse!
      get :automation_monitor
      job_runs[0..29].each {|el| expect(assigns(:job_runs)).to include(el)}
      expect(assigns(:job_runs)).to_not include(job_runs[30])
      JobRun.delete_all
    end
  end

  context 'toggle_script_filter' do
    it 'returns open filter true' do
      get :toggle_script_filter, { open_filter: 'true' }
      expect(session[:open_script_filter]).to be_truthy
    end

    it 'returns open filter false' do
      get :toggle_script_filter
      expect(session[:open_script_filter]).to_not be_truthy
    end
  end
end

