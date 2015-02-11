################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class RoutesController < ApplicationController

  before_filter :set_application

  # mixin to add an archive, unarchive action set
  include ArchivableController

  def index
    authorize! :list, Route.new
    @per_page = params[:per_page] || 20
    @page = params[:page] || 1
    @routes = @app.routes.unarchived.in_name_order.paginate(:page => @page, :per_page => @per_page)
    @archived_routes = @app.routes.archived.in_name_order.paginate(:page => @page, :per_page => @per_page)

    # set the default tab to routes which is accessed from the apps/edit page
    @page_tab_selected = 'routes'
    respond_to do |format|
      # regular page index so do the whole template
      format.html { render :template => "apps/edit", :locals => {:routes => @routes} }
    end
  end

  def show
    authorize! :inspect, Route.new
    @route = find_route
    @available_environments = @app.environments - @route.environments

    respond_to do |format|
      if @route
        format.html # show.html.erb
        format.json { render json: @route }
      else
        format.json  { render json: @route.errors, :status => :not_found }
      end
    end
  end

  def new
    authorize! :create, Route.new
    @route = Route.new
  end

  def edit
    authorize! :edit, Route.new
    begin
      @route = find_route
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Route you are trying to access either does not exist or has been deleted"
      redirect_to(app_routes_path(@app)) && return
    end
  end

  def create
    authorize! :create, Route.new
    @route = @app.routes.create(params[:route])

    if @route.save
      flash[:notice] = 'Route was successfully created.'
      redirect_to app_route_path(@app, @route)
    else
      render :action => "new"
    end
  end

  def update
    authorize! :edit, Route.new
    @route = find_route

    if @route.update_attributes(params[:route])
      flash[:notice] = 'Route was successfully updated.'
      redirect_to app_route_path(@app, @route)
    else
      render :action => "edit"
    end
  end

  def destroy
    authorize! :delete, Route.new
    @route = find_route
    @route.destroy

    redirect_to app_routes_path(@app), notice: t('activerecord.notices.deleted', model: Route.model_name.human)
  end

  # a special action that takes an array of environment ids from check boxes
  # and adds them in bulk to the route member
  # special method to display short form of available runs and allow the user to add the run
  def add_environments
    # grab the environments being add as route gates...
    @new_environment_ids = params[:new_environment_ids]
    # find the run
    @route = find_route
    respond_to do |format|
      path = app_route_path(@app, @route)
      if @new_environment_ids.present? && @route.present? && @route.update_attributes(:new_environment_ids => @new_environment_ids)
        if request.xhr?
          format.html { ajax_redirect(path) }
        else
          format.html { redirect_to(path, :notice => 'Environments were successfully added to route.') }
          format.xml  { render :xml =>  @route, :status => :created, :location => @route }
        end
      else
        format.html { redirect_to(path, :notice => 'Sorry! Environments missing or invalid for route.') }
        format.xml  { render :xml => @route.errors, :status => :unprocessable_entity }
      end
    end
  end


  protected

  def set_application
    @app = App.find params[:app_id]
  end

  def find_route
    @app.routes.find params[:id]
  end

end
