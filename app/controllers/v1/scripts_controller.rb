class V1::ScriptsController < V1::AbstractRestController
  
  def index
    @scripts = Script.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @scripts.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => scripts_presenter }
        format.json { render :json => scripts_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  def show
    @script = Script.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @script.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => script_presenter }
        format.json { render :json => script_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def create
    @script = Script.new
    respond_to do |format|
      begin
        success = @script.update_attributes(params[:script])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end
      if success
        format.xml  { render :xml => script_presenter, :status => :created }
        format.json  { render :json => script_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @script.errors, :status => :unprocessable_entity }
        format.json  { render :json => @script.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @script = Script.find(params[:id].to_i) rescue nil
    puts @script
    respond_to do |format|
      if @script
        begin
        # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @script.toggle_archive
            @script.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
          elsif params[:script].present?
            success = @script.update_attributes_with_state(params[:script])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => script_presenter, :status => :accepted }
          format.json  { render :json => script_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @script.errors, :status => :unprocessable_entity }
          format.json  { render :json => @script.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def destroy
    @script = Script.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @script
        success = @script.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => script_presenter, :status => :precondition_failed }
          format.json { render :json => script_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the scripts presenter
  def scripts_presenter
    @scripts_presenter ||= V1::ScriptsPresenter.new(@scripts, @template)
  end

  # helper for loading the script present
  def script_presenter
    @script_presenter ||= V1::ScriptPresenter.new(@script, @template)
  end
end
