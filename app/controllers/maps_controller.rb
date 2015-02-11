################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class MapsController < ApplicationController

  def index
    authorize! :view, :maps_reports
  end

  def versions_by_app
    authorize! :view, :component_versions_map
    @apps = current_user.apps.with_installed_components

    if request.post? and params[:application_environment_ids].present?
      @selected_app = App.includes(:application_components).find(params[:app_id])
      @selected_app_id = @selected_app.id
      @selected_application_environments = @selected_app.application_environments.includes(:installed_components).in_order.find_all_by_id(params[:application_environment_ids])
      @selected_application_environment_ids = @selected_application_environments.map { |app_env| app_env.id }
      @selected_application_environments.flatten!
      @selected_application_environment_ids.flatten!
    end
  end

  def components_by_environment
    @environments_for_select = current_user.accessible_default_environments

    if request.post?
      @environments = Environment.find_all_by_id(params[:environment_ids])
    end
#   @filter_proc = proc { |*args|
#     server_aspects = args.first
#     component = args.last
#     server_aspects.select { |aspect| aspect.components.include? component }
#   }
  end

  def servers
    authorize! :view, :server_map
    @environment_ids = params[:environment_ids].try(:map, &:to_i)
    @environment_for_select = Environment.id_equals(@environment_ids)

    @server_ids = params[:server_ids].try(:map, &:to_i)
    @servers = Server.id_equals(@server_ids)

    @server_level_ids = params[:server_level_ids].try(:map, &:to_i)

    @filter_proc = proc do |server_aspects, server_level_ids|
      server_aspects.select { |sa| server_level_ids.include? sa.server_level_id if server_level_ids }
    end
  end

  def servers_by_app
    authorize! :view, :servers_map_by_app
    @map = MapsPresenter.new
  end

  def servers_by_environment
    @environments = current_user.accessible_environments.sort_by(&:name)
  end

  def logical_servers
    selected_environments = current_user.accessible_environments.sort_by(&:name)

    @levels_by_environment = {}
    selected_environments.each do |environment|
      server_levels = environment.servers.map { |s| s.server_aspects }.flatten.group_by { |sa| sa.server_level }

      grouper = proc { |aspects|
        grouper.call(
          aspects.map { |a| a.server_aspects }.flatten.each do |aspect|
            server_levels[aspect.server_level] = (server_levels[aspect.server_level] || []) + [aspect]
          end
        ) unless aspects.blank?
      }

      server_levels.each_value do |aspects|
        grouper.call(aspects)
      end

      server_levels.each_value do |aspects|
        aspects.map! { |a| a.server }
        aspects.uniq!
      end

      @levels_by_environment[environment] = server_levels
    end
  end

  def properties
    authorize! :view, :properties_map
    @apps = current_user.accessible_apps

    if request.post? and params[:application_environment_ids].present?
      @selected_app = App.find(params[:app_id])
      @selected_app_id = @selected_app.id
      @app_env_ids_with_eg = params[:application_environment_ids]

      @selected_application_environments = @selected_app.application_environments.id_equals(@app_env_ids_with_eg)

      @selected_application_environment_ids = @selected_application_environments.map { |app_env| app_env.id }

      @selected_components = @selected_app.components.includes(:properties).find(params[:component_ids]) if params[:component_ids].present?
      @selected_component_ids = @selected_components.map { |app_env| app_env.id } if @selected_components.present?

      @releases = Release.find_all_by_id(params[:release_ids])
    end
  end

  # FIXME: When merging with develop, a lot of changes had been made to this routine that were not in my environmental
  # groups removal branch.  I kept the changes that were in develop, but this code needs to be rechecked.
  def application_component_summary
    authorize! :view, :app_component_summary_map
    @apps_for_select = current_user.accessible_apps
    @selected_environments = (params[:environment_ids] || [])
    @selected_app_ids = params[:app_ids].try(:map) { |id| id.to_i }
    @selected_application_environment_ids = params[:application_environment_ids].try(:map) { |id| id.to_i }
    @selected_component_ids = params[:component_ids].try(:map) { |id| id.to_i }

    apps = App.find_all_by_id @selected_app_ids
    components = Component.find_all_by_id @selected_component_ids
    application_environments = ApplicationEnvironment.find_all_by_id @selected_application_environment_ids

    unless components.blank?
      @map = MapsPresenter.new
    end
    render :partial => "maps/application_component_summary", :locals => { :map => @map, :apps => apps,  :application_environments => application_environments,  :components => components } if request.xhr?
  end

  def environments
    @environments_for_select = current_user.accessible_default_environments
    @apps_for_select = current_user.accessible_apps
    @server_levels_for_select = ServerLevel.in_order

    if request.post?
      @selected_environments = (params[:environment_ids] || [])
      @selected_environment_ids = (params[:environment_ids] || []).map(&:to_i)
      @selected_app_ids = (params[:app_ids] || []).map(&:to_i)

      remaining_environment_ids = @selected_environment_ids
      @environments = []
      ordering_app = App.find_by_id(@selected_app_ids.first) || @apps_for_select.first
      if ordering_app
        @environments = ordering_app.environments.find_all_by_id(@selected_environment_ids)
        remaining_environment_ids -= ordering_app.environment_ids
      end

      @environments += Environment.with_apps(@selected_app_ids).find_all_by_id(remaining_environment_ids)

      @selected_server_level_ids = params[:server_level_ids].try(:map, &:to_i)
      @server_levels = ServerLevel.find_all_by_id(@selected_server_level_ids)

      @map = []
      @server_levels.each do |sl|
        row = [sl.name]
        @environments.each do |e|
          server_aspects = sl.server_aspects.name_order.with_environments(e).with_apps(@selected_app_ids)
          physical_servers = server_aspects.map { |sa| sa.server }
          row << physical_servers.map { |ps| ps.name }.uniq.join(', ')
          row << server_aspects.map { |sa| sa.name }.uniq.join(', ')
        end
        @map << row
      end
    end
  end

  # Added to get application environments options for selected applications
  def multiple_application_environment_options
    app_ids = params[:app_ids]
    app_ids = [app_ids].flatten
    unless app_ids.blank?
      options = ""
      App.where(:id => app_ids).order('apps.name asc').each do |app|
        apply_method = current_user.has_global_access? ? nil : "app_environments_visible_to_user"
        options += "<optgroup class='app' label='#{app.name}'>"
        options += options_from_model_association(app, :application_environments, :apply_method => apply_method)
        options += "</optgroup>"
      end
    render :text => options
    else
    render :nothing => true
    end
  end

  def component_options
    if params[:application_environment_ids].to_s.include?("_")
      environment_ids, application_environment_ids = [],[]
      environment_ids << params[:application_environment_ids].select{|ids| ids.include?("_")}.collect {|x| x.split("_").first}
      environment_ids = environment_ids.flatten.compact
      application_environment_ids << params[:application_environment_ids].reject{|ids| ids.include?("_")}.collect{|x| x}
    application_environment_ids = application_environment_ids.flatten.compact
    application_environment_ids << ApplicationEnvironment.find_all_by_environment_id_and_app_id(environment_ids,params[:app_ids]).map(&:id)
    application_environment_ids.flatten!
    else
    application_environment_ids = params[:application_environment_ids]
    end
    application_component_ids = ApplicationComponent.find_all_by_app_id(params[:app_ids]).map { |app_comp| app_comp.id }
    installed_components = InstalledComponent.find_all_by_application_environment_id_and_application_component_id(application_environment_ids, application_component_ids)
    components = installed_components.map { |inst_comp| inst_comp.component }.uniq
    render :text => ApplicationController.helpers.options_from_collection_for_select(components, :id, :name)
  end

  def property_options
    apps = App.find_all_by_id(params[:app_ids])
    properties = apps.map { |app| app.properties }.flatten.uniq

    render :text => ApplicationController.helpers.options_from_collection_for_select(properties, :id, :name)
  end

  def server_aspect_group_options
    apps = App.find_all_by_id(params[:app_ids])
    server_aspect_groups = apps.map { |app| app.installed_components.map { |ic| ic.server_aspects.map { |sa| sa.groups } } }.flatten.uniq

    render :text => ApplicationController.helpers.options_from_collection_for_select(server_aspect_groups, :id, :name)
  end

  def application_environment_and_component_options_for_app
    @selected_app = App.find_by_id(params[:app_id])
    @selected_app_id = @selected_app.id if @selected_app
    apply_method = "application_environments.acccessible_to_user(current_user).having_installed_components.in_order"
    selected_application_environment_ids = (params[:selected_application_environment_ids] || []).map { |id| id.to_i }
    @application_environment_options = options_from_model_association(@selected_app, :application_environments,
                                                                      {:apply_method => apply_method,
                                                                      :selected => selected_application_environment_ids})

    selected_component_ids = (params[:selected_component_ids] || []).map { |id| id.to_i }
    @component_options = options_from_model_association(@selected_app, :components, :selected => selected_component_ids)
  end

  def application_environment_options_for_app
    @selected_app = App.find_by_id(params[:app_id])
    @selected_app_id = @selected_app.id if @selected_app
    apply_method = "application_environments.acccessible_to_user(current_user).having_installed_components.in_order"
    render :text => options_from_model_association(@selected_app, :application_environments, :apply_method => apply_method)
  end

  def component_options_for_app
    @selected_app = App.find_by_id(params[:app_id])
    @selected_app_id = @selected_app.id if @selected_app

    render :text => options_from_model_association(@selected_app, :components)
  end

  def server_options_for_environment
    @selected_environment = Environment.find_by_id(params[:environment_id])
    @selected_environment_id = @selected_environment.id if @selected_environment

    render :text => options_from_model_association(@selected_environment, :servers, :find => { :order => 'name' })
  end

  def property_value_history
    app_environment = ApplicationEnvironment.find(params[:application_environment_id])
    components = Component.find(params[:component_ids])
    date = Time.parse(params[:custom_value_change_date])

    installed_components = components.map { |comp| app_environment.installed_component_for(comp) }.compact

    property_values = installed_components.inject([]) do |list, inst_component|
      inst_component.properties.each do |field|

        field_value = field.property_value_for_date_and_installed_component_id(date, inst_component)
        field_value = "<em>#{field_value}</em>" if field.static_for? inst_component.app

        field_was_changed_at_given_time = field.value_changed_at_date_for_installed_component_id?(date, inst_component.id)

        if field_value
          list << { :property_id => field.id, :value => field_value, :needs_highlight => field_was_changed_at_given_time }
        else
          list << { :property_id => field.id, :value => '', :needs_highlight => false }
        end
      end
      list
    end

    render :json => property_values + [:application_environment_id => params[:application_environment_id]]
  end

end

