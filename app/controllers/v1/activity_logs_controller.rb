class V1::ActivityLogsController < V1::AbstractRestController

  def index
    @activity_logs = ActivityLog.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @activity_logs.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => activity_logs_presenter }
        format.json { render :json => activity_logs_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  def show
    @activity_log = ActivityLog.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @activity_log.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => activity_log_presenter }
        format.json { render :json => activity_log_presenter }
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

  # helper for loading the activity_logs presenter
  def activity_logs_presenter
    @activity_logs_presenter ||= V1::ActivityLogsPresenter.new(@activity_logs, @template)
  end

  # helper for loading the activity_log present
  def activity_log_presenter
    @activity_log_presenter ||= V1::ActivityLogPresenter.new(@activity_log, @template)
  end
end
