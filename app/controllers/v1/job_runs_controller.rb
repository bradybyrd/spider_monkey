class V1::JobRunsController < V1::AbstractRestController

  def index
    @job_runs = JobRun.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @job_runs.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => job_runs_presenter }
        format.json { render :json => job_runs_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  def show
    @job_run = JobRun.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @job_run.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => job_run_presenter }
        format.json { render :json => job_run_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # special case of a model that can only be created through programmatic automation
  def create
    respond_to do |format|
      format.xml  { head :method_not_allowed }
      format.json  { head :method_not_allowed }
    end
  end
  
  # special case of a model that can only be created through programmatic automation
  def update
    respond_to do |format|
      format.xml  { head :method_not_allowed }
      format.json  { head :method_not_allowed }
    end
  end
  
  # special case of a model that can only be created through programmatic automation
  def destroy
    respond_to do |format|
      format.xml  { head :method_not_allowed }
      format.json  { head :method_not_allowed }
    end
  end

  private

  # helper for loading the job_runs presenter
  def job_runs_presenter
    @job_runs_presenter ||= V1::JobRunsPresenter.new(@job_runs, @template)
  end

  # helper for loading the job_run present
  def job_run_presenter
    @job_run_presenter ||= V1::JobRunPresenter.new(@job_run, @template)
  end
end
