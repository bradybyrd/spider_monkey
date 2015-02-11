################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ServerAspectsController < ApplicationController
  before_filter :find_server_level

  def new
    @server_aspect = @server_level.server_aspects.build
    authorize! :add, @server_aspect
    grouped_parents = @server_level.grouped_potential_parents
    if !grouped_parents.empty?
      @selected_environment_ids = grouped_parents.first.last.first.try(:environment_ids)
      @server_aspect.parent = grouped_parents.first.last.first
    end
    render :template => 'server_aspects/load_form'
  end

  def create
    @server_aspect = @server_level.server_aspects.build(params[:server_aspect])
    authorize! :add, @server_aspect
    @server_aspect.save
    @page = params[:page]
    @key = params[:key]
    if request.xhr? && @server_aspect.valid?
      respond_to do |format|
        format.js { render :template => "server_aspects/update" }
      end
    else
      render :template => 'server_aspects/save'
    end
  end

  def edit
    @server_aspect = @server_level.server_aspects.find(params[:id])
    authorize! :edit, @server_aspect
    @selected_environment_ids = @server_aspect.environment_ids
    render :template => 'server_aspects/load_form'
  end

  def update
    if !params[:server_aspect].key?(:environment_ids)
      params[:server_aspect][:environment_ids]=Array.new;
    end
    if !params[:server_aspect].key?(:properties_with_value_ids)
      params[:server_aspect][:properties_with_value_ids]=Array.new;
    end
    @server_aspect = @server_level.server_aspects.find(params[:id])
    authorize! :edit, @server_aspect
    @server_aspect.update_attributes(params[:server_aspect])
    @page = params[:page]
    @key = params[:key]
    if request.xhr? && @server_aspect.valid?
      respond_to do |format|
        format.js { render :template => "server_aspects/update" }
      end
    else
      render :template => 'server_aspects/save'
    end
  end

  def destroy
    server_aspect = @server_level.server_aspects.find(params[:id])
    authorize! :delete, server_aspect
    @page = params[:page]
    @key = params[:key]
    flash[:error] = t('server_aspect.delete_error') unless server_aspect.destroy
  end

  def edit_property_values
    @server_aspect = @server_level.server_aspects.find(params[:id])
    authorize! :edit_property, @server_aspect
    render :layout => false
  end

  def update_property_values
    @server_aspect = @server_level.server_aspects.find(params[:id])
    authorize! :edit_property, @server_aspect

    params[:property_values].each do |property_id, new_value|
      Property.find(property_id).update_value_for_object(@server_aspect, new_value)
    end
  end

  def expand_tree
    @server_aspect = @server_level.server_aspects.find(params[:id])
    render :layout => false
  end

  def collapse_tree
    @server_aspect = @server_level.server_aspects.find(params[:id])
    render :layout => false
  end

  def environment_options
    parent = ServerAspect.find_by_type_and_id(params[:server_aspect][:parent_type_and_id])
    render :text => options_from_model_association(parent, :environments, :selected => parent.environment_ids, :named_scope => :name_order)
  end


  def update_environmentsList
    type, id =  params[:server_aspect_parent_type_and_id].split('::')
    @available_environments = case type
    when "Server"
      Server.find(id).environments
    when "ServerAspect"
      ServerAspect.find(id).environments
    when "ServerLevel"
      ServerLevel.find(id).environments
    when "ServerGroup"
      ServerGroup.find(id).environments
    else
      nil
    end
    @server_aspect = @server_level.server_aspects.build
  end

protected

  def find_server_level
    @server_level = ServerLevel.find(params[:server_level_id])
  end
end

