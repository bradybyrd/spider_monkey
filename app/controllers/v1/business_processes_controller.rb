class V1::BusinessProcessesController < V1::AbstractRestController
  def index
    @business_processes = BusinessProcess.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @business_processes.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => business_processes_presenter }
        format.json { render :json => business_processes_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  def show
    @business_process = BusinessProcess.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @business_process.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => business_process_presenter }
        format.json { render :json => business_process_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def create
    @business_process = BusinessProcess.new
    respond_to do |format|
      begin
        success = @business_process.update_attributes(params[:business_process])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => business_process_presenter, :status => :created }
        format.json  { render :json => business_process_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @business_process.errors, :status => :unprocessable_entity }
        format.json  { render :json => @business_process.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @business_process = BusinessProcess.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @business_process
        begin
          # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @business_process.toggle_archive
            @business_process.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
          # otherwise continue on with a standard update
          elsif params[:business_process].present?
            success = @business_process.update_attributes(params[:business_process])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => business_process_presenter, :status => :accepted }
          format.json  { render :json => business_process_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @business_process.errors, :status => :unprocessable_entity }
          format.json  { render :json => @business_process.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def destroy
    @business_process = BusinessProcess.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @business_process
        success = @business_process.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => business_process_presenter, :status => :precondition_failed }
          format.json { render :json => business_process_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the business_processes presenter
  def business_processes_presenter
    @business_processes_presenter ||= V1::BusinessProcessesPresenter.new(@business_processes, @template)
  end

  # helper for loading the business_process present
  def business_process_presenter
    @business_process_presenter ||= V1::BusinessProcessPresenter.new(@business_process, @template)
  end
end
