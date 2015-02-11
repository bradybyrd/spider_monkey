require 'spec_helper'

describe 'v1/job_runs' do
  before(:all) { @user = User.first || create(:user) }
  let(:base_url) { 'v1/job_runs' }
  let(:params)  { {token: @user.api_key} }
  subject { response }

  describe 'get /v1/job_runs' do
    before(:each) { @job_run = JobRun.first || create(:job_run) }
    let(:url) { base_url }

    it_behaves_like "successful request", type: :json do
      subject { response.body }
      it { should have_json('number.id').with_value(@job_run.id) }
      it { should have_json('string.job_type').with_value(@job_run.job_type) }
      it { should have_json('string.status').with_value(@job_run.status) }
      it { should have_json('number.run_key').with_value(@job_run.run_key) }
      it { should have_json('number.automation_id').with_value(@job_run.automation_id) }
      it { should have_json('string.started_at') }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }
    end

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('/job-runs/job-run[1]/id').with_text(@job_run.id) }
      it { should have_xpath('/job-runs/job-run[1]/job-type').with_text(@job_run.job_type) }
      it { should have_xpath('/job-runs/job-run[1]/status').with_text(@job_run.status) }
      it { should have_xpath('/job-runs/job-run[1]/run-key').with_text(@job_run.run_key) }
      it { should have_xpath('/job-runs/job-run[1]/automation-id').with_text(@job_run.automation_id) }
      it { should have_xpath('/job-runs/job-run[1]/started-at') }
      it { should have_xpath('/job-runs/job-run[1]/created-at') }
      it { should have_xpath('/job-runs/job-run[1]/updated-at') }
    end
  end

  describe 'get /v1/job_runs[id]' do
    before(:each) { @job_run = JobRun.first || create(:job_run) }
    let(:url) { "#{base_url}/#{@job_run.id}" }

    it_behaves_like "successful request", type: :json do
      subject { response.body }
      it { should have_json('number.id').with_value(@job_run.id) }
      it { should have_json('string.job_type').with_value(@job_run.job_type) }
      it { should have_json('string.status').with_value(@job_run.status) }
      it { should have_json('number.run_key').with_value(@job_run.run_key) }
      it { should have_json('number.automation_id').with_value(@job_run.automation_id) }
      it { should have_json('string.started_at') }
      it { should have_json('string.created_at') }
      it { should have_json('string.updated_at') }
    end

    it_behaves_like "successful request", type: :xml do
      subject { response.body }
      it { should have_xpath('/job-run/id').with_text(@job_run.id) }
      it { should have_xpath('/job-run/job-type').with_text(@job_run.job_type) }
      it { should have_xpath('/job-run/status').with_text(@job_run.status) }
      it { should have_xpath('/job-run/run-key').with_text(@job_run.run_key) }
      it { should have_xpath('/job-run/automation-id').with_text(@job_run.automation_id) }
      it { should have_xpath('/job-run/started-at') }
      it { should have_xpath('/job-run/created-at') }
      it { should have_xpath('/job-run/updated-at') }
    end
  end

  describe 'post /v1/job_runs' do
    let(:url) { "#{base_url}?token=#{@user.api_key}" }

    it_behaves_like "successful request", type: :json, method: :post, status: 405 do
      let(:job_type) { "automation" }
      let(:status)   { "Starting" }
      let(:run_key)  { 1323073373 }
      let(:automation_id) { 1 }
      let(:params) { {job_run: {job_type: job_type, status: status, run_key: run_key, automation_id: automation_id}}.to_json }
    end

    it_behaves_like "successful request", type: :xml, method: :post, status: 405 do
      let(:job_type) { "automation" }
      let(:status)   { "Starting" }
      let(:run_key)  { 1323073373 }
      let(:automation_id) { 1 }
      let(:params) { {job_run: {job_type: job_type, status: status, run_key: run_key, automation_id: automation_id}}.to_xml }
    end
  end

  describe 'put /v1/job_runs' do
    before(:each) { @job_run = JobRun.first || create(:job_run) }
    let(:url) { "#{base_url}/#{@job_run.id}?token=#{@user.api_key}" }

    it_behaves_like "successful request", type: :json, method: :put, status: 405 do
      let(:new_job_type) { "notification" }
      let(:new_status)   { "complete" }
      let(:new_run_key)  { 1323073376 }
      let(:new_automation_id) { 5 }
      let(:params) { {job_run: {job_type: new_job_type, status: new_status, run_key: new_run_key, automation_id: new_automation_id}}.to_json }
    end

    it_behaves_like "successful request", type: :xml, method: :put, status: 405 do
      let(:new_job_type) { "notification" }
      let(:new_status)   { "complete" }
      let(:new_run_key)  { 1323073374 }
      let(:new_automation_id) { 10 }
      let(:params) { {job_run: {job_type: new_job_type, status: new_status, run_key: new_run_key, automation_id: new_automation_id}}.to_xml }
    end
  end

  describe 'delete /v1/job_run[id]' do
    before :each do
      @json_job_run = create(:job_run)
      @xml_job_run  = create(:job_run)
    end

    it_behaves_like "successful request", type: :json, method: :delete, status: 405 do
      let(:url) { "#{base_url}/#{@json_job_run.id}?token=#{@user.api_key}" }
      let(:params) { {job_run: {id: @json_job_run.id}}.to_json }
    end

    it_behaves_like "successful request", type: :xml, method: :delete, status: 405 do
      let(:url) { "#{base_url}/#{@xml_job_run.id}?token=#{@user.api_key}" }
      let(:params) { {job_run: {id: @xml_job_run.id}}.to_xml }
    end
  end
end
