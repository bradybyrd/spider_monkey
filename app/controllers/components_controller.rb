################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class ComponentsController < ApplicationController
  include ControllerSoftDelete
  include AlphabeticalPaginator

  def index
    authorize! :list, Component.new

    @per_page = 30
    @keyword = params[:key]
    associations_to_include = [:application_components, :apps, :installed_components]
    accessible_components = current_user.accessible_components.includes(associations_to_include)
    @active_components = accessible_components.active.includes(:active_properties)
    @inactive_components = accessible_components.inactive.includes(:properties)
    if @keyword.present?
      @active_components = @active_components.search_by_ci("components.name", @keyword)
      @inactive_components = @inactive_components.search_by_ci("components.name", @keyword)
    end
    @active_components = alphabetical_paginator @per_page, @active_components
    @total_records = @active_components.count
    if @active_components.blank? and @inactive_components.blank?
      flash.now[:error] = I18n.t(:'activerecord.notices.not_found', model: 'Component')
    end
    render :partial => "index", :layout => false if request.xhr?
  end

  def new
    @component = Component.new

    authorize! :create, @component
  end

  def edit
    begin
     @component = find_component
     authorize! :edit, @component
    rescue ActiveRecord::RecordNotFound
     flash[:error] = I18n.t(:'activerecord.notices.not_found', model: 'Component')
      redirect_to :back
    end
  end

  def create
    @component = Component.new(params[:component])
    authorize! :create, @component
    @component.not_from_rest =  true
    if @component.save
      flash[:notice] = I18n.t(:'activerecord.notices.created', model: I18n.t(:'activerecord.models.component'))
      redirect_to components_path(:page => params[:page], :key => params[:key])
    else
      render :action => "new"
    end
  end

  def update
    @component = find_component
    authorize! :edit, @component
    @component.not_from_rest =  true
    if @component.update_attributes(params[:component])
      flash[:notice] = I18n.t(:'activerecord.notices.updated', model: I18n.t(:'activerecord.models.component'))
      redirect_to components_path(:page => params[:page], :key => params[:key])
    else
      render :action => "edit"
    end
  end

  def destroy
    @component = find_component
    authorize! :delete, @component
    @component.destroy

    redirect_to components_path(:page => params[:page], :key => params[:key]),
                notice: I18n.t(:'activerecord.notices.deleted', model: 'Component')
  end

  protected
    def find_component
      Component.find params[:id]
    end

end

