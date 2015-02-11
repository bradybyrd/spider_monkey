################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'will_paginate/array'

class ApplicationComponentsController < ApplicationController

  def index
    @app = find_app
    render :partial => 'apps/application_component_list', :locals => {:app => @app}
  end

  def update
    @app = find_app
    component = @app.application_components.find(params[:id])
    component.update_attributes(params[:component])

    render :partial => 'for_reorder', :locals => { :app => @app, :component => component }
  end

  def add_remove
    authorize! :add_remove, ApplicationComponent.new

    @app = find_app
    components = Component.active.all
    render :partial => 'application_components/add_remove', :locals => {:components => components, :app => @app, :page => params[:page], :key => params[:key]}
  end

  def copy_all
    authorize! :create, InstalledComponent.new
    @app = find_app

    @app.copy_all_components_to_all_environments
    redirect_to edit_app_path(@app, :page => params[:page], :key => params[:key])
  end

  def setup_clone_components
    @app = find_app
    authorize! :clone, InstalledComponent.new

    @app_environments = app_environments
    @environment_to_clone = @app_environments.all.find{|env| env.id == params[:environment_id].to_i}
    @environments = app_environments.reject{|env| env.id == @environment_to_clone.id }
    render :partial => 'apps/clone_components', :locals => {:app => @app, :environments => @environments, :environment_to_clone => @environment_to_clone }
  end

  def clone_components
    @app = find_app
    authorize! :clone, InstalledComponent.new

    @app_environments = app_environments
    new_app_environments = []
    if params[:new_environments] && can?(:create, Environment.new)
      params[:new_environments].delete_if { |env| env['name'].blank? }
      new_environments = Environment.create(params[:new_environments])
      new_environments.each do |env|
        new_app_environments << @app.application_environments.create(:environment_id => env.id)
      end
    end
    env_ids = params[:environment_ids] || []
    env_ids += new_app_environments.map{|env| env.id}
    environments_to_clone_to = @app_environments.find_all_by_id(env_ids)

    env_id = params[:env_to_clone_id]
    app_env_to_copy = @app_environments.find(env_id)
    @app.copy_components_across_environments app_env_to_copy.application_components, environments_to_clone_to
    redirect_to edit_app_path(@app, :page => params[:page], :key => params[:key])
  end

  def update_all
    authorize! :add_remove, ApplicationComponent.new

    @app = find_app
    @app.component_ids = params[:component_ids] || []
    @app.save

    if params[:new_components] && can?(:create, Component.new)
      @new_components = Component.create(params[:new_components])
      new_component_ids = @new_components.map(&:id).compact
    end

    component_ids = [params[:component_ids], new_component_ids].flatten.compact.map(&:to_i)

    # To record in RecentActivity when new Component added to App.
    (component_ids - @app.component_ids).each do |component_id|
      component = Component.find component_id
      # TODO: RJ: Rails 3: Log activity pending as plugin not working
      #current_user.log_activity(:context => "Component #{component.try(:name)} added to Application #{@app.name}") do
        component.update_attribute(:updated_at, component.updated_at)
        @app.application_components.create(:component_id => component_id)
      #end
    end

    steps_with_invalid_components = []
    @app.requests.active.each do |request|
      request.executable_steps.each do |step|
        next if component_ids.include?(step.component_id)
        next if step.complete?

        steps_with_invalid_components << step
      end
    end

    if steps_with_invalid_components.blank?
      @app.application_components.each do |app_comp|
        next if component_ids.include?(app_comp.component_id)

        app_comp.destroy
      end

      @app.reload
    else
      session[:components_to_be_destroyed] = @app.component_ids - component_ids
    end


    if is_components_valid?(@new_components)
      ajax_redirect(edit_app_path(@app, :steps_with_invalid_components => steps_with_invalid_components, :page => params[:page], :key => params[:key]))
    else
      respond_to do |format|
        @div = 'all_components'
        @div_content =  render_to_string(:template => 'application_components/_add_remove', :layout => false, :locals => {:components => Component.active.all, :app => @app, :page => params[:page], :key => params[:key], :new_component => @new_component})
        format.js { render :template => 'misc/update_div.js.erb', :content_type => 'application/javascript'}
      end
      #render :update do |page|
      #  page.replace_html "all_components", :partial => 'application_components/add_remove', :locals => {:components => Component.active.all, :app => @app, :page => params[:page], :key => params[:key], :new_component => @new_component}
      #end
    end
  end

  def add_component_mapping
   @app = find_app
   @application_component = @app.application_components.find(params[:id])
   authorize! :map_properties, @application_component

   project_servers = ProjectServer.active.all
   render :partial => "component_mappings/add_component_mapping", :locals => { :project_servers => project_servers, :edit_mode => false }
  end

  def edit_component_mapping
   @app = find_app
   @application_component = @app.application_components.find(params[:id])
   authorize! :map_properties, @application_component

   project_servers = @application_component.application_component_mappings.collect { |a| a.project_server }
   render :partial => "component_mappings/add_component_mapping", :locals => { :project_servers => project_servers, :edit_mode => true }
  end

  def resource_automations
    @app = find_app
    @application_component = @app.application_components.find(params[:id])

    @project_server_id = params[:project_server_id]

    if @project_server_id.present?
      @project_server = ProjectServer.find(@project_server_id)
      @resource_automations = @project_server.scripts.component_mapping_automations
      if params[:edit_mode] == "true"
        current_mappings = @application_component.application_component_mappings.where(:project_server_id => @project_server_id)
        if current_mappings && (current_mappings.size > 0)
          @selected_automation_id = current_mappings.first.script_id
        end
      end
    end

    render :partial => "component_mappings/resource_automations", :locals => { :project_server => @project_server,
                :resource_automations => @resource_automations, :edit_mode => params[:edit_mode], :selected_automation_id => @selected_automation_id}
  end

  def filter_arguments
    @app = find_app
    @application_component = @app.application_components.find(params[:id])
    @project_server_id = params[:project_server_id]

    @script_id = params[:script_id]
    prefilled_argument_values = {}
    if params[:edit_mode] == "true"
      current_mappings = @application_component.application_component_mappings.where(:project_server_id => @project_server_id)
      if current_mappings && (current_mappings.size > 0)
        mapping = current_mappings.first
        @script = mapping.script
        arguments_hash = mapping.data
        prefilled_argument_values = {}
        @script.arguments.each do |arg|
          prefilled_argument_values[arg.id] = { "value" => arguments_hash[arg.argument] || "" }
        end
      end
    else
      if @script_id.present?
        @script = Script.find(@script_id)
        # also look for saved arguments
        prefilled_argument_values = @script.filter_argument_values
      end
    end

    if @project_server_id.present?
      @project_server = ProjectServer.find(@project_server_id)
    end

    if @script.present?

      #script type may be passed, though if this routine is being used it is like a ResourceAutomation
      script_type = params[:script_type] || "ResourceAutomation"
      # consider mocking up a step for compatibility reasons until the automation
      # controls can be properly generalized.  Might be meaningful to also set the
      # script ids to something meaningful
      step = Step.new
      step.script_id = @script.id
      step.script_type = @script_type

      render  :partial => "component_mappings/filter_arguments",
              :locals => {
                :project_server => @project_server,
                :script => @script,
                :argument_values => prefilled_argument_values,
                :step => step,
                :installed_component => nil,
                :old_installed_component_id => nil,
                :edit_mode => params[:edit_mode]
               },
               :layout => false
    else
      flash.now[:error] = "Unable to find component mappings filter with script id: #{ @script_id || 'blank'}."
      render nothing: true
    end
  end

  def delete_mapping
    @app = find_app
    @application_component = @app.application_components.find(params[:id])
    authorize! :map_properties, @application_component

    current_mappings = @application_component.application_component_mappings.where(:project_server_id => params[:project_server_id])
    if current_mappings && (current_mappings.size > 0)
      ac = current_mappings.first
      ac.destroy
    end

    ajax_redirect(edit_app_path(@app))
  end

  def save_mapping
    @app = find_app
    @application_component = @app.application_components.find(params[:id])
    authorize! :map_properties, @application_component

    params[:argument] ||= {}
    params.each do |k,v|
      if k.match('tree_renderer_')
        ar_id =  k.match(/[0-9 -()+]+$/)[0]
        params[:argument][ar_id] = v.split(',')
      end
    end

    argument_hash = {}
    # cycle through the form variables to see what has been set, ignoring blank values
    params[:argument].each do |key, value|
      argument_name = ScriptArgument.find(key).argument
      # guarantee that all values are an array
      value = Array(value)
      # select box values are coming through as single element arrays
      if value.length < 2
        argument_hash[argument_name] = value[0] unless value.blank? || value[0].blank?
      else
        argument_hash[argument_name] = value
      end
    end

    ac = nil
    if params[:edit_mode] == "true"
      current_mappings = @application_component.application_component_mappings.where(:project_server_id => params[:project_server_id])
      if current_mappings && (current_mappings.size > 0)
        ac = current_mappings.first
        ac.update_attributes(:script_id => params[:script_id], :data => argument_hash)
      end
    else
      ac = @application_component.application_component_mappings.create(:project_server_id => params[:project_server_id],
            :script_id => params[:script_id], :data => argument_hash)
    end
    if ac.errors.size > 0
      respond_to do |format|
        @div = 'errors'
        @div_content =  render_to_string(:template => 'misc/error_messages_for', :layout => false, :locals => {:item => ac})
        format.js { render :template => 'misc/update_div.js.erb', :content_type => 'application/javascript'}
      end
    else
      ajax_redirect(edit_app_path(@app))
    end
  end

  def edit_property_values
    @app = find_app
    @page_no = params[:page] || 1
    @application_component = @app.application_components.find(params[:id])
    authorize! :edit_properties, @application_component

    @app_environments = @application_component.application_environments.in_order.
        paginate(:page => params[:page], :per_page => 3)
    @property_number = params[:property_number] if params[:property_number]
    @property = Property.find(params[:property_id]) if params[:property_id]
    @properties = order_params_property_ids(params[:property_ids]) if params[:property_ids]
    @new_property_ids = params[:property_numbers].uniq if params[:property_numbers]

    if params[:add_property].present? && params[:show_view].blank?
      render :partial => 'application_components/add_property',
             :locals => {:app => @app,
                         :application_component => @application_component,
                         :app_environments => @app_environments}
    # TODO: didn't find where this param is going from
    elsif params[:show_view].present?
      render :partial => 'application_components/edit_property_values',
             :locals => {:app_environments => @app_environments,
                         :application_component => @application_component,
                         :app => @app, :properties => @properties,
                         :property_number => @property_number,
                         :new_property => @property_number.present?,
                         :new_property_ids => @new_property_ids }
    elsif params[:show_property].present?
      render :partial => 'application_components/show_properties',
             :locals => {:app => @app, :application_component => @application_component,
                         :property => @property,
                         :app_environments => @app_environments,
                         :property_number => @property_number }
    else
      render :layout => false
    end
  end

  def update_property_values
    @app = find_app
    @application_component = @app.application_components.find(params[:id])
    authorize! :edit_properties, @application_component

    @remove_properties = params[:component_property].keys if params[:component_property].present?

    if !params[:main_property_value_form].present? && params[:properties].present?
      @new_properties = Property.create_new_instance(params[:properties], [@application_component.component.id])
      @validated_properties = Property.validate_all(@new_properties)

      if !can?(:create, Property.new)
        error_message = I18n.t(:'activerecord.notices.no_permissions',
                               action: I18n.t(:create),
                               model: I18n.t(:'activerecord.models.property'))
        property_error_message error_message
      elsif @validated_properties.blank?
        # All properties are valid so save them !
        Property.save_all(@new_properties,:application_component => @application_component,:properties => params)
        respond_to do |format|
          format.js { render :template => 'application_components/property_success_create', :handlers => [:erb], :content_type => 'application/javascript'}
        end
      else
        # One or more properties are invalid
        # dummy property is not saved but to collect error messages of all new invalid properties
        property_error_message Property.validation_errors_of(@validated_properties)
      end
    else
      @success = nil
      if @application_component.application_environments.blank?
        update_value_for_uninstalled_component
      else
        @application_component.application_environments.each do |app_env|
          @installed_component = app_env.installed_component_for(@application_component.component)
          if params["property_values_#{app_env.id}"].present?
            params["property_values_#{app_env.id}"].each do |property_id, value|
              if @remove_properties.present? && @remove_properties.include?(property_id)
                Property.find(property_id).remove_property_for_installed_component(@installed_component, @application_component)
              else
                locked = params[:property_values_locked][property_id] == 'true'
                Property.find(property_id).update_value_for_installed_component(@installed_component, value, locked)
              end
              if params[:update_comp_prop_assoc].present?
                component_ids = Property.find(property_id).component_ids
                component_ids << @application_component.component.id unless component_ids.include?(@application_component.component.id)
                if Property.find(property_id).update_attributes({:component_ids => component_ids})
                  @success = true
                end
              end
            end
          end
        end
      end

    end
  end

protected

  def find_app
    App.find(params[:app_id])
  end

  def app_environments
    @app.application_environments
  end


  def validate_properties(properties)
    validate = {}
    properties.values.each do |name|
      @property = Property.new({:name => name})
      validate[@property.valid?] = name
    end
    validate
  end

  def order_params_property_ids(property_ids)
    # edit component from application >> add properties >> existing property list
    # properties should have in  same order for all environments (According to user added)
    properties = []
    property_ids.uniq.each do |property_id|
      property = Property.find(property_id)
      properties << property
    end
    properties
  end

  def update_value_for_uninstalled_component
    # update the property of application component which is not installed in any application environment
    if params[:property_id_for_uninsalled_component].present?
      params[:property_id_for_uninsalled_component].keys.each do |property_id|
        component_ids = Property.find(property_id).component_ids
        component_ids << @application_component.component.id unless component_ids.include?(@application_component.component.id)
        if  Property.find(property_id).update_attributes({:component_ids => component_ids})
          @success = true
        end
      end
    end
    # Remove component's property  which is not installed in any application environment
    if @remove_properties.present?
      @remove_properties.each do |property_id|
        comp_property = ComponentProperty.find_by_component_id_and_property_id(@application_component.component.id,property_id)
        if comp_property.present?
          comp_property.destroy
        end
      end
    end
  end

  def is_components_valid?(new_components)
    unless params[:new_components].first.has_key?("name")
      return true
    else
      new_components.each do |nc|
        @new_component = nc
        return false unless nc.save
      end
      true
    end
  end

  private

  def property_error_message(errors)
    @div          = 'property_error_messages'
    @scroll       = true
    @div_content  = render_to_string(template: 'misc/ajax_error_message_body', layout: false,
                                     locals: { options: {errors: errors} })

    respond_to do |format|
      format.js { render template: 'misc/update_div', handlers: [:erb], content_type: 'application/javascript' }
    end
  end

end

