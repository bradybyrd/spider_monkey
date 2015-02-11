################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PropertiesController < ApplicationController
  include ControllerSoftDelete
  include ControllerSearch
  include AlphabeticalPaginator

  skip_before_filter :authenticate_user!, :only => [:rest]

  # GET /properties
  # GET /properties.json
  def index
    authorize! :list, Property.new

    @per_page = 30
    @keyword = params[:key]
    @active_properties = Property.active
    @inactive_properties = Property.inactive.sorted
    if @keyword.present?
      @active_properties = @active_properties.search_by_ci('name', @keyword )
      @inactive_properties = @inactive_properties.sorted.search_by_ci('name', @keyword )
    end
    @total_records = @active_properties.length
    if !@active_properties.blank?
      @active_properties =  alphabetical_paginator @per_page, @active_properties
    end
    if @active_properties.blank? and @inactive_properties.blank?
      flash.now[:error] = t(:l10n_msg_property_no_properties)
    end
    respond_to do |format|
      if request.xhr?
        format.html{render :partial => 'index' ,:layout => false }
      else
        format.html # index.html.erb
      end
    end
  end

  # GET /properties/1
  # GET /properties/1.json
  def show
    @property = Property.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @property }
    end
  end

  # GET /properties/new
  # GET /properties/new.json
  def new
    @property = Property.new
    authorize! :create, @property

    if params[:object].present?
      @object = params[:object]
      @object_id = params[:object_id]
      eval("@property.#{params[:object]}_ids = [#{params[:object_id]}]")
      #render :layout => false
    end

    respond_to do |format|
      format.html { render :layout => !params[:object].present? }
      #format.json { render json: @property }
      #format.js { render :layout => !params[:object].present? }
    end
  end

  # GET /properties/1/edit
  def edit
    @property = Property.find(params[:id])
    authorize! :edit, @property
  end

  # GET /properties/1/edit_values
  def edit_values
    edit
  end

  # POST /properties
  # POST /properties.json
  def create
    component_ids = params[:property].delete(:component_ids) || []
    execution_task_ids = params[:execution_task_ids] || []
    creation_task_ids = params[:creation_task_ids] || []

    @property = Property.new(params[:property].merge(:component_ids => component_ids,
                                                     :execution_task_ids => execution_task_ids,
                                                     :creation_task_ids => creation_task_ids))

    authorize! :create, @property

    respond_to do |format|
      if @property.save
        format.html { redirect_to @property, notice: t('activerecord.notices.created', :model => Property.model_name.human) }
        format.json { render json: @property, status: :created, location: @property }
        format.js {
          flash[:notice] = t('activerecord.notices.created', :model => Property.model_name.human)
          ajax_redirect(params[:redirect_to] || properties_path(:page => params[:page], :key => params[:key]))
        }
      else
        format.html { render action: "new" }
        format.json { render json: @property.errors, status: :unprocessable_entity }
        format.js {
            @property.valid?
            show_validation_errors(:property, {:div => "property_error_messages"})
        }
      end
    end
  end

  # PUT /properties/1
  # PUT /properties/1.json
  def update
    @property = Property.find(params[:id])
    authorize! :edit, @property

    if params["name_update"].nil? ### If complete form is getting submitted, package all stuff
      @property.old_app_ids = @property.apps.map(&:id)
      component_ids = params[:property].delete(:component_ids) || []
      package_ids = params[:property].delete(:package_ids) || []
      execution_task_ids = params[:execution_task_ids] || []
      creation_task_ids = params[:creation_task_ids] || []
      server_ids = params[:property][:server_ids] || []
      server_level_ids = params[:property][:server_level_ids] || []
      app_ids = params[:property][:app_ids] || []
      old_server_ids  = @property.server_ids

      params[:property].merge!(:component_ids => component_ids,
                               :package_ids => package_ids,
                              :execution_task_ids => execution_task_ids,
                              :creation_task_ids => creation_task_ids,
                              :server_ids => server_ids,
                              :server_level_ids => server_level_ids,
                              :app_ids => app_ids
                             )
    end

    respond_to do |format|
      if @property.update_attributes(params[:property])
        if params["name_update"].nil? ### If complete form is submitted, make sure old server ids no more used are removed.
          @property.archive_server_property_values!(old_server_ids - @property.server_ids)
        end

        format.html { redirect_to @property, notice: t('activerecord.notices.updated', :model => Property.model_name.human) }
        format.json { head :no_content }
        format.js {
          flash[:notice] = t('activerecord.notices.updated', :model => Property.model_name.human)
          ajax_redirect(params[:redirect_to] || properties_path(:page => params[:page], :key => params[:key]))
        }
      else
        format.html { render action: "edit" }
        format.json { render json: @property.errors, status: :unprocessable_entity }
        format.js {
            @property.valid?
            show_validation_errors(:property, {:div => "property_error_messages"})
        }
      end
    end
  end

  # DELETE /properties/1
  # DELETE /properties/1.json
  def destroy
    @property = Property.find(params[:id])
    @property.destroy

    respond_to do |format|
      format.html { redirect_to properties_url }
      format.json { head :no_content }
    end
  end

  def properties_for_request
    @request = Request.find_by_number(params[:request_id])
    @step = @request.steps.find_or_initialize_by_id(params[:step_id])
    @step.assign_attributes(params[:step])
    @step.installed_component_id = @step.get_installed_component.try(:id)
    @step.own_version = GlobalSettings[:commit_on_completion]
    @work_task = WorkTask.find_by_id(params[:work_task_id])
  end

  def reorder
    component = Component.find(params[:component_id])
    component_property = ComponentProperty.find_by_component_id_and_property_id(params[:component_id], params[:id])
    component_property.update_attributes(params[:property])

    render :partial => 'properties/property_list', :locals => { :properties => component.properties.active, :component_id => params[:component_id] }
  end

  def rest
    render :template => 'properties/rest.builder', :layout => false, :locals => { :message => status_msg }
  end

  protected

  def find_property
    Property.find params[:id]
  end
end
