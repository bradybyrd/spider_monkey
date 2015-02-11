################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ServerLevelPropertiesController < ApplicationController
  before_filter :find_server_level, :except => [:properties_for_step]

  def new
    @property = @server_level.properties.build
    authorize! :create, @property
    @page = params[:page]
    @key = params[:key]
    render :partial => 'form'
  end

  def create
    @property = @server_level.properties.build(params[:property])
    authorize! :create, @property
    @page = params[:page]
    @key = params[:key]
    if @server_level.save && request.xhr?
      respond_to do |format|
        format.js { render :template => 'server_level_properties/update' }
      end
    else
      render :template => 'server_level_properties/save'
    end
  end

  def edit
    @property = @server_level.properties.find(params[:id])
    authorize! :edit, @property
    render :partial => 'form'
  end

  def update
    @property = @server_level.properties.find(params[:id])
    authorize! :edit, @property
    @property.update_attributes(params[:property])
    render :template => 'server_level_properties/save'
  end

  def destroy
    authorize! :delete_property, @server_level
    @server_level.properties.destroy(params[:id])
  end

  protected

  def find_server_level
    @server_level = ServerLevel.find(params[:server_level_id])
  end
end

