################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class MapsPresenter
  def generate_servers_by_app_map apps
    app_list = '<ul>'
    apps.each { |app| app_list << "<li>#{app.name}#{servers_for_map(app)}</li>" }
    app_list << '</ul>'
    app_list.html_safe
  end

  def servers_for_map(app)
    return '' if app.servers_with_installed_components.empty?
    servers_part = '<ul>'
    app.servers_with_installed_components.each do |server|
      servers_part << "<li>#{server.name}#{server_levels_for_map(app, server)}</li>"
    end
    servers_part << '</ul>'
  end

  def server_levels_for_map(app, server)
    aspects_by_level = server.aspects_below.group_by { |aspect| aspect.server_level }
    return '' if app.installed_components.empty? or aspects_by_level.empty?
    levels_part = '<ul>'
    app.installed_components.each do |ic|
      aspects_by_level.each do |level, aspects|
        current_aspects = aspects & (ic.server_aspects.any? ? ic.server_aspects : ic.server_aspects_through_groups)
        next if current_aspects.empty?
        levels_part << "<li>#{level.name}#{server_aspects_for_map(app, ic, aspects)}</li>"
      end
    end
   return '' if levels_part == '<ul>'
   levels_part << '</ul>'
  end

  def server_aspects_for_map(app, installed_component, aspects)
    aspect_list = aspects.select { |aspect| aspect.has_components_on_app? app }.map
    # In Ruby 1.9.x map fucntion returns an Enumerator so we need to convert enumerator into an array before applying
    # any array specifc functions
    return '' if aspect_list.try(:to_a).try(:empty?)
    aspects_part = '<ul>'
     aspect_list.each do |aspect|
      aspects_part << "<li>#{aspect.name}:#{installed_component.environment.name}<ul><li>#{installed_component.name}</li></ul></li>"
    end
    aspects_part << '</ul>'
  end

  def raw_map
    @build ||= []
  end

  def reset_map!
    @build = []
  end

  def to_html build = self.raw_map
    total = '<ul>'
    build.each do |val|
      if String === val
        total << "<li>#{val}</li>"
      else
        total << to_html(val)
      end
    end
    total << '</ul>'
  end


# Adding following method to display Application Component summary report in tree structure

  def generate_application_component_summary(apps,app_envs,components)
    return 'Please select applications, environments and components to the right.' if apps.blank? || app_envs.blank? || components.blank?
    app_list = '<ul>'
    apps.each { |app| app_list << "<li>#{app.name}#{application_environments_for_map(app, app_envs,components)}</li>" }
    app_list << '</ul>'
    app_list.html_safe
  end

  def application_environments_for_map(app, app_envs, components)
    env_list = '<ul>'
    app_envs.each {|app_env| (env_list <<  "<li>#{app_env.environment.name}#{installed_component_for_map(app, app_env, components)}</li>") if app_env.app_id == app.id}
    env_list << '</ul>'
    env_list.html_safe
  end

  def installed_component_for_map(app, app_env, components)
    application_component_ids = ApplicationComponent.find_all_by_app_id_and_component_id(app.id,  components).map { |app_comp| app_comp.id }
    installed_components = InstalledComponent.find_all_by_application_environment_id_and_application_component_id(app_env.id,  application_component_ids)
    comp_list = '<ul>'
    installed_components.each{|installed_component| comp_list << "<li>#{installed_component.name}#{servers_for_installed_component(installed_component)}</li> "} unless installed_components.blank?
    comp_list << '</ul>'
  end

  def servers_for_installed_component installed_component
    server_list = '<ul>'
    installed_component.server_associations.each{ |s| server_list << "<li>#{s.name}</li>"}
    server_list << '</ul>'
  end

end

