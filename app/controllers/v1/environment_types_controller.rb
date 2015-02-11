class V1::EnvironmentTypesController < V1::AbstractRestController
 
  def index
    @environment_types = EnvironmentType.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @environment_types.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => environment_types_presenter }
        format.json { render :json => environment_types_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  
  def show
    @environment_type = EnvironmentType.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @environment_type.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => environment_type_presenter }
        format.json { render :json => environment_type_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def create
    @environment_type = EnvironmentType.new
    respond_to do |format|
      begin
        success = @environment_type.update_attributes(params[:environment_type])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => environment_type_presenter, :status => :created }
        format.json  { render :json => environment_type_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @environment_type.errors, :status => :unprocessable_entity }
        format.json  { render :json => @environment_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  
  def update
    @environment_type = EnvironmentType.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @environment_type
        begin
          # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @environment_type.toggle_archive
            @environment_type.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
            # otherwise continue on with a standard update  
          elsif params[:environment_type].present?
            success = @environment_type.update_attributes(params[:environment_type])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => environment_type_presenter, :status => :accepted }
          format.json  { render :json => environment_type_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        elsif
          format.xml  { render :xml => @environment_type.errors, :status => :unprocessable_entity }
          format.json  { render :json => @environment_type.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  
  def destroy
    @environment_type = EnvironmentType.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @environment_type
        success = @environment_type.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => environment_type_presenter, :status => :precondition_failed }
          format.json { render :json => environment_type_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the environment_types presenter
  def environment_types_presenter
    @environment_types_presenter ||= V1::EnvironmentTypesPresenter.new(@environment_types, @template)
  end

  # helper for loading the environment_type present
  def environment_type_presenter
    @environment_type_presenter ||= V1::EnvironmentTypePresenter.new(@environment_type, @template)
  end
end
