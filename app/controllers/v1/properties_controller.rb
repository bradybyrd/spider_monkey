class V1::PropertiesController < V1::AbstractRestController
  
  # Returns properties that are active by default
  def index
    @properties = Property.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @properties.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => properties_presenter }
        format.json { render :json => properties_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a property by property id
  def show
    @property = Property.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @property.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        
        format.xml { render :xml => property_presenter }
        format.json { render :json => property_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new property from a post request
  def create
    @property = Property.new
    respond_to do |format|
      begin
        success = @property.update_attributes(params[:property])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => property_presenter, :status => :created }
        format.json  { render :json => property_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @property.errors, :status => :unprocessable_entity }
        format.json  { render :json => @property.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing property with values from a PUT request
   def update
    @property = Property.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @property
        begin
          success = @property.update_attributes(params[:property])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => property_presenter, :status => :accepted }
          format.json  { render :json => property_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @property.errors, :status => :unprocessable_entity }
          format.json  { render :json => @property.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a property by deactivating them
  def destroy
    @property = Property.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @property
        success = @property.try(:deactivate!) rescue false
        
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => property_presenter, :status => :precondition_failed }
          format.json { render :json => property_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end
  
  private

  # helper for loading the properties presenter
  def properties_presenter
    @properties_presenter ||= V1::PropertiesPresenter.new(@properties, @template)
  end
    
  # helper for loading the property present  
  def property_presenter
    @property_presenter ||= V1::PropertyPresenter.new(@property, @template)
  end
end
