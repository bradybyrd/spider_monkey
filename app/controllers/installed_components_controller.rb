################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class InstalledComponentsController < ApplicationController
  before_filter :find_app, :except => [:add_remove_servers, :update_servers]
  before_filter :find_installed_component, :except => [:create, :add_remove_servers, :update_servers]

  def create
    authorize! :create, InstalledComponent.new

    unless @installed_component = @app.installed_components.find(:first, :conditions => params[:installed_component])
      @installed_component = InstalledComponent.create(params[:installed_component])
    end


    render :partial => "apps/application_environment_edit_row", :locals => {:app => @app, :application_environment => @installed_component.application_environment }
  end

  def edit
    authorize! :manage_servers, @installed_component

    @available_server_associations = if @installed_component.environment.servers.present?
      @installed_component.environment.server_associations.group_by { |assoc| assoc.server_level }
    else
      {}
    end

    @available_server_associations.delete(Server)
    @servers = @installed_component.application_environment.environment.servers_with_default_first
    @server_groups = @installed_component.environment.server_groups_with_default_first
    @server_aspect_groups = ServerAspectGroup.all

    render :layout => false
  end

  def update
    authorize! :manage_servers, @installed_component
    #FIXME: This should be done in the model so all setters benefit from exclusivity of these properties

    # prepare params
    if params[:server_association_type] == 'server'
    # server_ids
      params[:installed_component].delete(:default_server_group_id)
      params[:installed_component].delete(:server_aspect_ids)
      params[:installed_component].delete(:server_aspect_group_ids)
    elsif params[:server_association_type] == 'server_group'
    # default_server_group_id
      params[:installed_component].delete(:server_ids)
      params[:installed_component].delete(:server_aspect_ids)
      params[:installed_component].delete(:server_aspect_group_ids)
    elsif params[:server_association_type] == 'server_aspect_group'
    # server_aspect_group_ids
      params[:installed_component].delete(:server_ids)
      params[:installed_component].delete(:server_aspect_ids)
      params[:installed_component].delete(:default_server_group_id)
    else
    # server_aspect_ids
      params[:installed_component].delete(:server_ids)
      params[:installed_component].delete(:default_server_group_id)
      params[:installed_component].delete(:server_aspect_group_ids)
    end


    #version = (GlobalSettings.limit_versions? ? @installed_component.versions.find_by_name(params[:installed_component][:version]).try(:name) : params[:installed_component][:version]) if params[:installed_component][:version]
    params[:installed_component][:version] = params[:installed_component][:version] if params[:installed_component][:version]
    @installed_component.attributes = params[:installed_component]

    if params[:property_values]
      params[:property_values].each do |property_id, value|
        Property.find(property_id).update_value_for_installed_component(@installed_component, value)
      end
      @installed_component.update_property_value_for_app_comp
    end
    #@steps = @installed_component.steps_using_component
    #logger.info "SS__ IC save: #{@installed_component.inspect}, save?: #{(params.has_key?(:save_anyway)).to_s}"
    @installed_component.save if params.has_key?(:save_anyway) #|| @steps.count == 0
    clear_assoc_objects
  end

  def destroy
    authorize! :destroy, @installed_component

    @installed_component.destroy
    render :nothing => true
  end

  def add_remove_servers
    authorize! :manage_servers, InstalledComponent.new

    @application_environment = ApplicationEnvironment.find(params[:application_environment_id])
    @available_server_associations = if @application_environment.environment.servers.present?
      @application_environment.environment.server_associations.group_by { |assoc| assoc.server_level }
    else
      {}
    end
    render :layout => false
  end

  def update_servers
    authorize! :manage_servers, InstalledComponent.new

    installed_components = InstalledComponent.find_all_by_id(params[:installed_component_ids])
    installed_components.each { |ic| ic.add_server_associations(params[:server_level_id], params[:server_ids_to_add]) }
    installed_components.each { |ic| ic.remove_server_associations(params[:server_level_id], params[:server_ids_to_remove]) }

    update_steps_servers! installed_components

    render :json => find_installed_servers(installed_components)
  end

protected
  def find_app
    @app = App.find params[:app_id]
  end

  def find_installed_component
    @installed_component = @app.installed_components.find(params[:id])
  end

  def clear_assoc_objects
    @installed_component.clear_assoc_objects({
      :servers => params[:installed_component][:server_ids],
      :server_aspects => params[:installed_component][:server_aspect_ids],
      :server_aspect_groups => params[:installed_component][:server_aspect_group_ids]
    })
  end

  def update_steps_servers!(installed_components)
    component_ids                   = installed_components.collect{ |ic| ic.component_id }
    subject                         = params[:server_level_id] == "0" ? :servers : :server_aspects
    server_ids_to_remove_from_steps = params[:server_ids_to_remove].to_a - params[:server_ids_to_add].to_a
    InstalledComponent.update_steps_servers(subject, server_ids_to_remove_from_steps, component_ids)
  end

  def find_installed_servers(installed_components)
    server_associations = {}
    installed_components.each do |installed_component|
      list = installed_component.server_associations
      sentence = list.map { |obj| name_of(obj) }.to_sentence
      server_associations[installed_component.id] = sentence
    end
    server_associations
  end

  def name_of(model)
    model && model.name || ''
  end
end
