class PlanRoutesController < ApplicationController
  layout :choose_layout

  before_filter :find_plan
  before_filter :find_related_application, :only => [:new, :create]
  before_filter :select_page_tab

  def index
    authorize! :list, PlanRoute.new
    @plan_routes = @plan.plan_routes.in_app_name_order.paginate(:page => @page ||= 1, :per_page => @per_page ||= 25)

    render 'plans/show', :formats => [:html]
  end

  def show
    @plan_route = @plan.plan_routes.find(params[:id])
    authorize! :inspect, @plan_route
    @plan_stage_instances = @plan.plan_stage_instances.in_plan_stage_position_order
  end

  def new
    @plan_route = PlanRoute.new(:plan_id => @plan.id) unless @plan.blank?
    authorize! :assign_app, @plan_route

    respond_to do |format|
      if @plan_route
        if request.xhr?
          format.html
        else
          format.html
          format.xml  { render :xml => @plan_route }
        end
      else
        format.html { redirect_to(plan_plan_routes_path(@plan), :error => 'Plan Route could not be created due to invalid parameters.') }
        format.xml  { head :unprocessable_entity }
      end
    end
  end

  def create

    # route_app_id is just used to scope the list of routes, so exclude
    # but cache in case save fails and we need to reload routes for their
    # route_app_id selection
    @route_app_id = params[:plan_route].try(:delete, :route_app_id)

    @plan_route =  @plan.plan_routes.build(params[:plan_route])
    authorize! :assign_app, @plan_route

    respond_to do |format|
      if @plan_route.save && !@route_app_id.blank?
        path = plan_plan_route_path( @plan, @plan_route )
        if request.xhr?
          format.html { ajax_redirect(path) }
        else
          format.html { redirect_to(path, :notice => 'Plan Route was successfully created.') }
          format.xml  { render :xml => @plan_route, :status => :created, :location => @plan_route }
        end
      else
        # route_plan has no app so this field is pseudo-validated
        @plan_route.errors[:app] = "can't be blank" if @route_app_id.blank?

        # preload the routes for the selected route_app_id
        routes = App.find_by_id(@route_app_id).try(:routes) || []
        @routes_for_select = routes.map { |r| [r.name.try(:truncate, 25), r.id ]} || []
        if request.xhr?
          format.html { show_validation_errors(:plan_route, {:div => 'plan_route_error_messages'}) }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @plan_route.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def destroy
    @plan_route = PlanRoute.find(params[:id])
    authorize! :delete_from_plan, @plan_route
    @plan_route.destroy

    respond_to do |format|
      format.html { redirect_to( plan_plan_routes_url(@plan) ) }
      format.xml  { head :ok }
    end
  end


def add_constraints
  # actions to add route gates from params array
end

  private

  def select_page_tab
    # signal to the plan/show template that the page tab selected is plan_routes
    @page_tab_selected = 'routes'
  end

  def find_plan
    @plan = Plan.find_by_id(params[:plan_id])
  end

  def choose_layout
    (request.xhr?) ? nil : 'application'
  end

  def find_related_application
    # first get all the applications scoped by the current user
    @applications = current_user.accessible_apps_for_requests
    # do not allow user to assign multiple routes from the same application
    @applications = @applications.where('apps.id NOT IN (?)', @plan.routed_apps) unless @plan.routed_apps.blank?
  end
end
