require 'spec_helper'

describe JobRunsController, :type => :controller do
  context "#index" do
    it "returns flash 'No Job Runs found' and render action" do
      pending "missing template"
      JobRun.delete_all
      get :index
      flash[:error].should include('No Job Runs')
    end

    it "returns records with pagination" do
      pending "missing template"
      @job_runs = 51.times.collect{create(:job_run,
                                          :started_at => Time.now - 1.weeks,
                                          :job_type => "Resource Automation")}
      @job_runs.reverse!
      get :index
      @job_runs[0..29].each {|el| assigns(:job_runs).should include(el)}
      assigns(:job_runs).should_not include(@job_runs[30])
    end

  end

  it "#show" do
    @job_run = create(:job_run)
    get :show, {:id => @job_run.id}
    response.should render_template('show')
  end

  it "#destroy" do
    @job_run = create(:job_run)
    expect{delete :destroy, {:id => @job_run.id}
          }.to change(JobRun, :count).by(-1)
    response.should redirect_to(automation_monitor_path)
  end
end
