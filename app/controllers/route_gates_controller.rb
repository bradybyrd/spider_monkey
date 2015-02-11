class RouteGatesController < ApplicationController

  before_filter :set_route_and_route_gate, :only => [:update, :destroy]

  def update
    authorize! :configure_gates, Route.new
    @route_gate.update_attributes(params[:route_gate])
    render :partial => 'routes/for_reorder', :locals => { :app => @app, :route_gate => @route_gate }
  end

  def destroy
    authorize! :configure_gates, Route.new
    @route_gate.destroy
    redirect_to app_route_path(@app, @route), :notice => 'Route gate was successfully deleted.'
  end

  protected

  def set_route_and_route_gate
    @route_gate = RouteGate.find_by_id(params[:id])
    @route = @route_gate.route
    @app = @route.app
  end
end
