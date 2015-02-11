require 'spec_helper'
require File.expand_path(File.join('lib', 'script_support', 'ssh_script_header.rb'))

describe 'Script Helper File' do
  describe '#load_input_params' do
    before :each do
      YAML.stub(:load).and_return params
      File.stub(:open)
    end

    let(:params){ script_params_hash }

    it 'should parse the private params correctly' do
      result_params = load_input_params 'from some file'

      result_params['password'].should == 'awwtgl02!'
    end
  end
end

def script_params_hash
  {
      SS_script_support_path: File.expand_path(File.join('lib', 'script_support')),
      SS_script_target: 'ssh',
      SS_script_type: 'step',
      SS_token: '103_820_1389716505',
      application: 'app_1',
      arguments: '',
      command: 'ls',
      component: 'comp_2',
      component_version: '1',
      hosts: '10.128.36.153',
      password: '__SS__CmhJRE1zZEdkM2RYWQ==',
      prop_1: '2',
      request_application: 'app_1',
      request_cancellation_category: '',
      request_environment: 'env_1',
      request_environment_type: 'Development',
      request_id: '1103',
      request_login: 'admin',
      request_name: 'de_r_3_ssh',
      request_number: '1103',
      request_owner: 'Administrator, John',
      request_plan: '' ,
      request_plan_id: '',
      request_plan_member_id: '-1',
      request_plan_stage: '',
      request_planned_at: '2014-01-14 08:11:45 -0600',
      request_process: 'business_process_1',
      request_project: '',
      request_release: '',
      request_requestor: 'Administrator, John',
      request_run_id: '',
      request_run_name: '',
      request_scheduled_at: '',
      request_started_at: '2014-01-14 10:21:45 -0600',
      request_status: 'started',
      request_wiki_url: '',
      servers: 'serv_1',
      step_description: '',
      step_estimate: '5',
      step_id: '820',
      step_name: 's',
      step_number: '1',
      step_owner: 'Administrator, John',
      step_phase: '',
      step_runtime_phase: '',
      step_started_at: '2014-01-14 08:11:52 -0600',
      step_task: '',
      step_user_id: '1',
      step_version: '',
      sudo: '',
      ticket_ids: '',
      tickets_foreign_ids: '',
      user: 'root'
  }.stringify_keys!
end