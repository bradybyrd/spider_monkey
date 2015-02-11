class V1::RoutesController < V1::AbstractRestController
 
  def index
    @routes = Route.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @routes.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => routes_presenter }
        format.json { render :json => routes_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  
  def show
    @route = Route.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @route.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => route_presenter }
        format.json { render :json => route_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def create
    @route = Route.new
    respond_to do |format|
      begin
        success = @route.update_attributes(params[:route])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => route_presenter, :status => :created }
        format.json  { render :json => route_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @route.errors, :status => :unprocessable_entity }
        format.json  { render :json => @route.errors, :status => :unprocessable_entity }
      end
    end
  end

  
  def update
    @route = Route.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @route
        begin
          # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @route.toggle_archive
            @route.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
            # otherwise continue on with a standard update  
          elsif params[:route].present?
            success = @route.update_attributes(params[:route])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => route_presenter, :status => :accepted }
          format.json  { render :json => route_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        elsif
          format.xml  { render :xml => @route.errors, :status => :unprocessable_entity }
          format.json  { render :json => @route.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  
  def destroy
    @route = Route.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @route
        success = @route.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => route_presenter, :status => :precondition_failed }
          format.json { render :json => route_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the routes presenter
  def routes_presenter
    @routes_presenter ||= V1::RoutesPresenter.new(@routes, @template)
  end

  # helper for loading the route present
  def route_presenter
    @route_presenter ||= V1::RoutePresenter.new(@route, @template)
  end
end
