class ConstraintsController < ApplicationController
  layout :choose_layout

  before_filter :find_constraint, :only => [:create, :update, :destroy]

  def create

    @plan_route = PlanRoute.find(params[:plan_route_id])
    @constraint = Constraint.new(params[:constraint])
    authorize! :configure, @constraint

    respond_to do |format|
      if @constraint.save
        path = plan_plan_route_path(@plan_route.plan, @plan_route)
        if request.xhr?
          format.html { ajax_redirect(path) }
        else
          format.html { redirect_to(path, :notice => 'Constraint was successfully created.') }
          format.xml { render :xml => @constraint, :status => :created, :location => @constraint }
        end
      else
        if request.xhr?
          format.html { show_validation_errors(:constraint, {:div => 'constraint_error_messages'}) }
        else
          format.html { render :action => "new" }
          format.xml { render :xml => @constraint.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def update
    # TODO: find where this is called from
    path = governable_path(@constraint)

    success = @constraint.update_attributes(params[:category])

    respond_to do |format|
      format.html { redirect_to path, :notice => (success ? 'Constraint was successfully updated.' : 'There was a problem updatingx the constraint.') }
    end
  end

  def destroy
    # constraints can be owned by a number of different objects
    # so grab the governable type and object and route success
    # or failure by that object's path
    authorize! :configure, @constraint
    path = governable_path(@constraint)
    success = @constraint.destroy

    respond_to do |format|
      format.html { redirect_to path, :notice => (success ? 'Constraint was successfully removed.' : 'There was a problem removing the constraint.') }
    end
  end


  private

  def find_constraint
    @constraint = Constraint.find_by_id(params[:id])
  end

  def choose_layout
    (request.xhr?) ? nil : 'application'
  end

  def governable_path(constraint)
    case constraint.constrainable_type
      when 'RouteGate' then
         plan_route = PlanRoute.where(:plan_id => constraint.governable.plan_id, :route_id => constraint.constrainable.route_id).try(:first)
         plan_plan_route_path(plan_route.plan, plan_route)
       else
         root_path
     end
  end
end
