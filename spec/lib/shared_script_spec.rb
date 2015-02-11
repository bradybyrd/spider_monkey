require 'spec_helper'

describe 'SharedScript' do
  before :each do
    @background = mock 'background'
    @user = create :deployment_coordinator
    Script.stub(:background) {@background}
    User.stub(:find_by_login) {@user}
  end

  let(:script)  { create :general_script }
  let(:step)    { create :step_with_script }
  let(:queue_table) { AutomationQueueData }

  describe '#queue_run!' do
    it 'class with module should include method' do
      script.should respond_to :queue_run!
    end

    it 'should enqueue the run' do
      AutomationCommon.stub(:build_params).and_return("request_notes"=>'headers_for_request')
      AutomationCommon.stub(:init_run_files).and_return(true)
      @background.should_receive(:background_run)
      script.queue_run! step
    end

    it 'should create a queue imprint' do
      AutomationCommon.stub(:build_params).and_return("request_notes"=>'headers_for_request')
      AutomationCommon.stub(:init_run_files).and_return(true)
      @background.stub(:background_run)

      expect{script.queue_run!(step)}.to change(queue_table, :count).from(0).to(1)
      last_in_queue = queue_table.last

      last_in_queue.step_id.should  == step.id
    end
  end

  describe '#background_run' do
    context 'shadow queue' do
      before :each do
        @job_run          = double('job_run').as_null_object
        @activity_log     = double('@activity_log').as_null_object
        Step.stub(:find)        { step_mock }
        JobRun.stub(:find)      { @job_run }
        ActivityLog.stub(:new)  { @activity_log }
        Script.any_instance.stub(:choose_run_script).and_return 'OK'
        Script.any_instance.stub(:fetch_url)
        step_mock.stub(:id).and_return step.id
        step_mock.stub(:complete?).and_return false
      end
      let(:params)    { background_run_params }
      let(:step_mock) { double(step).as_null_object }

      it 'should clear queue\'s imprints' do
        queue_table.create(attempts: 0, run_at: Time.now, step_id: step.id)

        expect{script.background_run(params)}.to change(queue_table, :count).from(1).to(0)
      end
    end
  end
end

describe SharedScript do
  class Wrapper
    include SharedScript

    def automation_type
      'Automation'
    end

    def logger
    end

    def content
      'content'
    end

    def wr_parse_arguments
      parse_arguments
    end
  end

  let(:wrapper) { Wrapper.new }

  it '#bladelogic?' do
    wrapper.stub(:methods).and_return(['authentication'])
    wrapper.bladelogic?.should be_truthy
  end

  it '#ssh?' do
    wrapper.stub(:bladelogic?).and_return(false)
    wrapper.ssh?.should be_truthy
  end

  it '#capistrano' do
    wrapper.stub(:bladelogic?).and_return(false)
    wrapper.capistrano.should be_truthy
  end

  describe '#get_script_type' do
    specify 'BladelogicScript' do
      wrapper.stub(:class).and_return(BladelogicScript)
      wrapper.get_script_type.should eql('bladelogic')
    end

    specify 'ssh' do
      wrapper.stub(:automation_category).and_return('General')
      wrapper.get_script_type.should eql('ssh')
    end

    specify 'hudson' do
      wrapper.stub(:automation_category).and_return('Hudson/Jenkins')
      wrapper.get_script_type.should eql('hudson')
    end

    specify 'remedy' do
      wrapper.stub(:automation_category).and_return('BMC Remedy 7.6.x')
      wrapper.get_script_type.should eql('remedy')
    end

    specify 'resource_automation' do
      wrapper.stub(:automation_category).and_return(nil)
      wrapper.stub(:automation_type).and_return('ResourceAutomation')
      wrapper.get_script_type.should eql('resource_automation')
    end

    specify 'baa' do
      wrapper.stub(:automation_category).and_return('BMC Application Automation 8.2')
      wrapper.get_script_type.should eql('baa')
    end

    specify 'rlm' do
      wrapper.stub(:automation_category).and_return('RLM Deployment Engine')
      wrapper.get_script_type.should eql('rlm')
    end

    specify 'script' do
      wrapper.stub(:automation_category).and_return(nil)
      wrapper.stub(:class).and_return(Script)
      wrapper.get_script_type.should eql('script')
    end
  end

  describe '#choose_run_script' do
    it 'runs automation' do
      wrapper.stub(:class).and_return(Script)
      wrapper.stub(:run_automation_script).and_return('automation')
      wrapper.choose_run_script(nil).should eql('automation')
    end

    it 'runs bladelogic' do
      wrapper.stub(:class).and_return(BladelogicScript)
      wrapper.stub(:run_bladelogic_script).and_return('bladelogic')
      wrapper.choose_run_script(nil).should eql('bladelogic')
    end
  end

  describe '#in_use_by' do
    let(:step) { create(:step_with_script) }
    let(:script) { step.script }

    specify 'steps_count_present' do
      script.in_use_by.should eql(1)
    end

    specify 'steps_count_empty' do
      step.request.update_attribute(:aasm_state, "deleted")
      script.in_use_by.should eql(0)
    end
  end

  describe '#queue_run!' do
    before(:each) do
      AutomationCommon.stub(:build_params).and_return({})
      AutomationCommon.stub(:build_server_params).and_return({})
      AutomationCommon.stub(:init_run_files).and_return(true)
      wrapper.stub(:get_script_type).and_return('Script')
      @step = create(:step)
      @script = create(:general_script)
      @step.stub(:script).and_return(@script)
      wrapper.stub(:id).and_return(@script.id)
      wrapper.stub(:name).and_return(@script.name)
      wrapper.logger.stub(:info).and_return(true)
    end

    it "execute in background" do
      # pending "./lib/automation_backgroundable.rb:28:in `method_missing'"
      Wrapper.stub_chain(:background,:background_run).and_return(true)
      wrapper.queue_run!(@step).should be_truthy
      Wrapper.unstub(:background)
    end

    it 'execute out background' do
      result = wrapper.queue_run!(@step, nil, false)
      result['SS_script_target'].should eql('Script')
      result['SS_script_type'].should eql('step')
    end
  end

  describe '#background_run' do
    let(:user) { create(:old_user) }
    let(:request) { create(:request) }
    let!(:step) { create(:step, :request => request) }
    let(:job_run) { create(:job_run) }
    let(:params) { {'request_login' => user.login,
                    'step_id' => step.id,
                    'SS_job_run_id' => job_run.id,
                    'SS_wait_for_signal' => nil,
                    'SS_api_token' => 'some api key'}}

    before(:each) do
      step.script = create(:general_script)
      step.save
      request.plan_it!
      request.start!
      step.reload
      step.lets_start!
      wrapper.stub(:choose_run_script).and_return('Script output writte')
    end

    it "returns 'Denied'" do
      Request.any_instance.stub(:finish!).and_return(true)
      step.reload
      step.all_done!
      step.reload
      wrapper.background_run(params).should eql('Attempt to run script on a completed step - Denied')
    end

    it "returns 'encountered a problem'" do
      AutomationCommon.stub(:error_in?).and_return(true)
      wrapper.background_run(params)
      job_run.reload
      job_run.status.should eql('Problem')
    end

    it "returns 'Complete'" do
      # pending "undefined method `gsub' for nil:NilClass"
      AutomationCommon.stub(:error_in?).and_return(false)
      Request.any_instance.stub(:finish!).and_return(true)
      AutomationCommon.stub(:decrypt).and_return(1)
      wrapper.background_run(params)
      job_run.reload
      job_run.status.should eql('Complete')
    end

    it "returns 'waiting for remote signal'" do
      AutomationCommon.stub(:error_in?).and_return(false)
      wrapper.background_run({'request_login' => user.login,
                              'step_id' => step.id,
                              'SS_job_run_id' => job_run.id,
                              'step_user_id' => user.id,
                              'SS_wait_for_signal' => true})

      pending 'activity logs are saved in background now'
      step.logs.last.activity.should include('Automation for staying in-process')
    end
  end

  it '#step_automation_delay' do
    wrapper.step_automation_delay.should eql(6)
  end

  describe '#set_values_from_script' do
    it 'returns nothing' do
      wrapper.set_values_from_script('SS').should eql(nil)
    end

    it 'returns list objects' do
      wrapper.instance_variable_set('@log', AutomationLog.new)
      wrapper.stub(:process_script_list).and_return('')
      result = wrapper.set_values_from_script("\$\$SS_Set_{ObjectSS_Set_{property1}\$\$")
      result.should include('Found 1 entries')
      result.should include('List objects from script: Object')
    end
  end

  describe '#process_script_list' do
    before(:each) { wrapper.instance_variable_set('@step', create(:step)) }

    it 'returns nil' do
      wrapper.instance_variable_set('@step', nil)
      wrapper.process_script_list('servers', "$$SS_Set_{servers}$$\nServer1").should eql(nil)
    end

    it 'returns server properties' do
      result = wrapper.process_script_list('Servers', "$$SS_Set_Servers{Server1,Server2,Server3\nServer}$$")
      result.should include('SS_ Updating Servers from script')
      result.should include('Server1,Server2,Server3')
    end

    it 'returns component properties' do
      result = wrapper.process_script_list('Components', "$$SS_Set_Components{Copm1,Comp2,Comp3\nComp}$$")
      result.should include('SS_ Updating Components from script')
      result.should include('Setting version to:  on')
    end

    it 'returns property values' do
      result = wrapper.process_script_list('Property', "$$SS_Set_Property{Prop1,Prop2,Prop3\nProp}$$")
      result.should include('SS_ Updating Property from script')
      result.should include("[\"Prop1,Prop2,Prop3\", \"Prop\"]No value")
    end

    it 'returns properties values' do
      result = wrapper.process_script_list('Properties', "$$SS_Set_Properties{Prop1,Prop2,Prop3\nProp}$$")
      result.should include('SS_ Updating Properties from script')
      result.should include("[\"Prop1,Prop2,Prop3\", \"Prop\"]No value")
    end

    it 'returns applications values' do
      result = wrapper.process_script_list('Application', "$$SS_Set_Application{App1,App2,App3\nApp}$$")
      result.should include('SS_ Updating Application from script')
      result.should include("[\"App1,App2,App3\", \"App\"]")
    end

    it 'returns property value' do
      result = wrapper.process_script_list('Property', "$$SS_Set_Property{Prop1\n}$$")
      result.should include('SS_ Updating Property from script')
      result.should include("[\"Prop1\"]No value")
    end

    it 'returns application value' do
      result = wrapper.process_script_list('Application', "$$SS_Set_Application{App1\n}$$")
      result.should include('SS_ Updating Application from script')
      result.should include("[\"App1\"]")
    end
  end

  describe '#set_property_value' do
    let(:step) { create(:step) }
    let(:property) { create(:property) }

    before(:each) do
      wrapper.instance_variable_set('@step', step)
      wrapper.instance_variable_set('@log', AutomationLog.new)
      create_installed_component
      step.app_id = @app.id
    end

    it "returns 'No value'" do
      wrapper.set_property_value('Prop1').should eql('No value')
    end

    it 'saves value to local level' do
      wrapper.stub(:make_value_hash).and_return({'name' => "#{property.name}",
                                                 'value' => 'val1',
                                                 'component' => "#{@component.name}",
                                                 'environment' => "#{@env.name}"})
      wrapper.set_property_value("#{property.name}").should include('Saving at local request level')
    end

    it 'saves value to global dictionary' do
      wrapper.stub(:make_value_hash).and_return({'name' => 'Prop1',
                                                 'value' => 'val1',
                                                 'component' => "#{@component.name}",
                                                 'environment' => "#{@env.name}",
                                                 'global' => 'true'})
      result = wrapper.set_property_value("#{property.name}")
      result.should include('Forcing save to global property dictionary')
      result.should include('Creating new property: Prop1')
    end
  end

  it '#set_server_value' do
    create_installed_component
    request = create(:request, :environment => @env)
    step = create(:step, :request => request)
    server = create(:server)
    server_group = create(:server_group)
    step.installed_component = @installed_component
    wrapper.instance_variable_set('@step', step)
    wrapper.stub(:parse_set_row).and_return({'name' => server.name,
                                             'group' => server_group.name,
                                             'environment' => @env.name})
    result = wrapper.set_server_value('server1', 'group => group')
    result.should eql("Server: #{server.name}, in env: #{@env.name}, Group: #{server_group.name}")
  end

  describe '#set_component_value' do
    before(:each) do
      create_installed_component
      wrapper.stub(:parse_set_row).and_return({'name' => @component.name,
                                               'application' => @app.name,
                                               'environment' => @env.name})
      request = create(:request, :environment => @env)
      request.apps = [@app]
      step = create(:step, :request => request)
      wrapper.instance_variable_set('@step', step)
    end

    it "returns 'setting version to'" do
      wrapper.set_component_value("#{@component.name}", nil).should eql("Setting version to:  on #{@component.name}")
    end

    it "returns 'component is not present'" do
      ApplicationEnvironment.stub(:find_or_create_by_app_id_and_environment_id).and_return(nil)
      wrapper.set_component_value('Component1', nil).should eql("Component: #{@component.name} is not present in the #{@env.name}")
    end
  end

  describe '#set_application_value' do
    it "returns 'Could not find app'" do
      wrapper.stub(:make_value_hash).and_return({'name' => 'App1'})
      wrapper.instance_variable_set('@step', create(:step))
      wrapper.set_application_value('App1').should eql('Could not find app: App1 or Component not set on step')
    end

    it 'sets verion for app' do
      app = create(:app)
      wrapper.stub(:make_value_hash).and_return({'name' => "#{app.name}",
                                                 'value' => 'ver2.0'})
      wrapper.instance_variable_set('@step', create(:step))
      wrapper.set_application_value('App1').should eql("Application: #{app.name}, set version: ver2.0")
    end
  end

  it '#filter_argument_values' do
    arguments = create(:general_script).arguments
    wrapper.stub(:arguments).and_return(arguments)
    wrapper.filter_argument_values.should eql({arguments[0].id=>{'value' => ''}, arguments[1].id=>{'value' => ''}})
  end

  #=======private==========

  it '#parse_arguments' do
    #wrapper.stub(:argument_regex).and_return(/\s*^###\r?\n(.+?)(\r?\n)+?\s*^###\r?/m)
    #wrapper.stub(:content).and_return("string")
    #parse_arguments.should eql('string')
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

def background_run_params
  {
      'SS_run_key' =>1387894336,
      'SS_script_type' => 'step',
      'SS_script_target' => 'ssh',
      'direct_execute' => 'yes',
      'SS_script_support_path' =>"#{Rails.root}/lib/script_support",
      'SS_base_url' => 'http://10.128.36.226:3000',
      'SS_output_dir' => '/home/user/somedir',
      'success' => '', 'command' => 'ls',
      'SS_token' => '96_299_1387894336',
      'SS_process_pid' =>-1,
      'SS_callback_url' => 'http://10.128.36.226:3000/steps/299/1096/callback.xml?token=96_299_1387894336',
      'application' => 'app_1',
      'component' => 'comp_2',
      'SS_application' => 'app_1',
      'request_id' =>1096,
      'step_id' =>299,
      'step_number' => '1',
      'step_name' => 's1',
      'step_owner' => 'Administrator, John',
      'step_task' =>nil,
      'step_phase' =>nil,
      'step_runtime_phase' =>nil,
      'SS_environment' => 'env_1',
      'step_description' => '',
      'step_user_id' =>1,
      'step_started_at' => '2013-12-24 08:07:17 -0600',
      'step_estimate' =>5,
      'servers' => 'serv_1',
      'tickets_foreign_ids' => '',
      'ticket_ids' => '',
      'component_version' => '1',
      'SS_component' => 'comp_2',
      'SS_component_version' => '1',
      'step_version' =>nil,
      'prop_1' => '2',
      'request_name' => 'r_7',
      'request_status' => 'started',
      'request_plan_member_id' =>-1,
      'request_plan' => '',
      'request_plan_stage' => '',
      'request_project' => '',
      'request_started_at' => '2013-12-24 08:12:16 -0600',
      'request_planned_at' => '2013-12-20 07:20:47 -0600',
      'request_owner' => 'Administrator, John',
      'request_wiki_url' => '',
      'request_requestor' => 'Administrator, John',
      'request_application' => 'app_1',
      'request_number' =>1096,
      'SS_request_number' =>1096,
      'request_run_id' => '',
      'request_run_name' => '',
      'request_login' => 'admin',
      'request_plan_id' => '',
      'request_environment' => 'env_1',
      'request_environment_type' => 'Development',
      'request_scheduled_at' => '',
      'request_process' => 'business_process_1',
      'request_release' => '',
      'request_cancellation_category' => '',
      'SS_api_token' => '__SS__Cj09d016TUdPbUZUTTRZVE96WVdZd2tETTFrek00VWpaMVVHTWhaek00QURPMFFqWndVMk5pTldN',
      'SS_output_file' => '/home/user/somedir',
      'SS_input_file' => '/home/user/somedir',
      'SS_script_file' => '/home/user/somedir',
      'SS_automation_results_dir' => '/home/user/somedir',
      'SS_job_run_id' =>309,
      'SS_context_root' => ''
  }
end
