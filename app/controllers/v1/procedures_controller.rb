class V1::ProceduresController < V1::AbstractRestController
  
  def index
    @procedures = Procedure.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @procedures.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => procedures_presenter }
        format.json { render :json => procedures_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  def show
    @procedure = Procedure.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @procedure.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => procedure_presenter }
        format.json { render :json => procedure_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def create
    @procedure = Procedure.new
    respond_to do |format|
      begin
        success = @procedure.update_attributes(params[:procedure])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end
      if success
        format.xml  { render :xml => procedure_presenter, :status => :created }
        format.json  { render :json => procedure_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @procedure.errors, :status => :unprocessable_entity }
        format.json  { render :json => @procedure.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @procedure = Procedure.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @procedure
        begin
        # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @procedure.toggle_archive
            @procedure.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
          elsif params[:procedure].present?
            success = @procedure.update_attributes_with_state(params[:procedure])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => procedure_presenter, :status => :accepted }
          format.json  { render :json => procedure_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @procedure.errors, :status => :unprocessable_entity }
          format.json  { render :json => @procedure.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def destroy
    @procedure = Procedure.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @procedure
        success = @procedure.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => procedure_presenter, :status => :precondition_failed }
          format.json { render :json => procedure_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the procedures presenter
  def procedures_presenter
    @procedures_presenter ||= V1::ProceduresPresenter.new(@procedures, @template)
  end

  # helper for loading the procedure present
  def procedure_presenter
    @procedure_presenter ||= V1::ProcedurePresenter.new(@procedure, @template)
  end
end
