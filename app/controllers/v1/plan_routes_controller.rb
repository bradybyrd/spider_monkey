class V1::PlanRoutesController < V1::AbstractRestController
 
  def index
    @plan_routes = PlanRoute.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @plan_routes.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => plan_routes_presenter }
        format.json { render :json => plan_routes_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  def show
    @plan_route = PlanRoute.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @plan_route.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => plan_route_presenter }
        format.json { render :json => plan_route_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  def create
    @plan_route = PlanRoute.new
    respond_to do |format|
      begin
        success = @plan_route.update_attributes(params[:plan_route])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => plan_route_presenter, :status => :created }
        format.json  { render :json => plan_route_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @plan_route.errors, :status => :unprocessable_entity }
        format.json  { render :json => @plan_route.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @plan_route = PlanRoute.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @plan_route
        success = @plan_route.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => plan_route_presenter, :status => :precondition_failed }
          format.json { render :json => plan_route_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the plan_routes presenter
  def plan_routes_presenter
    @plan_routes_presenter ||= V1::PlanRoutesPresenter.new(@plan_routes, @template)
  end

  # helper for loading the plan_route present
  def plan_route_presenter
    @plan_route_presenter ||= V1::PlanRoutePresenter.new(@plan_route, @template)
  end
end
