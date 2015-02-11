class InstalledComponent < ActiveRecord::Base
  class << self
    
    def import_app(icomps_hash, app)
      icomps_hash.each do |icomp_data|
        env = Environment.find_by_name(icomp_data["application_environment"]["name"])
        comp = Component.find_by_name(icomp_data["application_component"]["component"]["name"])
        build_installed_component(icomp_data, env, comp, app)
      end
    end
    
    def build_installed_component(icomp_data, env, comp, app)
      app_env = ApplicationEnvironment.by_application_and_environment_names(app.name,env.name)
      app_comp = ApplicationComponent.by_application_and_component_names(app.name,comp.name)
      if app_comp
        installed_component = get_installed_component_and_params(app, comp, env, icomp_data)
        set_properties_on_installed_component(icomp_data, installed_component)       
      end 
    end
      
    
    def get_installed_component_and_params(app, comp, env, icomp_data)
      installed_component = create_or_find_for_app_component(app.id, comp.id, env.id)
      if installed_component.is_a?(Array)
        installed_component = installed_component.first
      end
      installed_component.version = icomp_data["version"] 
      installed_component.location = icomp_data["location"]         
      installed_component.server_group_name = icomp_data["server_group"]["name"] if icomp_data["server_group"]
      installed_component.server_names = get_existing_server_names(icomp_data["servers"]) if icomp_data["servers"]       
      installed_component.server_aspect_group_names = ServerAspectGroupImport.new(icomp_data["server_aspect_groups"], env).names
      installed_component.server_aspect_ids = ServerAspectImport.new(icomp_data["server_aspects"], env, nil).ids
      installed_component.save!
      installed_component
    end
    
    def get_existing_server_names(servers)
      names = []
      servers.each do |server_info|
        if server = Server.find_by_name(server_info["name"])
          names << server.name
        end
      end
      names
    end
        
    def set_properties_on_installed_component(icomp_data, installed_component)
      if icomp_data["find_properties"]
        icomp_data["find_properties"].each do |prop_val|
          Property.find_by_name(prop_val["name"]).update_value_for_object(installed_component, prop_val["value"],prop_val["locked"])
        end
        installed_component.update_property_value_for_app_comp
      end
    end
        
  end 
end