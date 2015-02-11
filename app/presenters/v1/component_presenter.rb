class V1::ComponentPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :component

  
  private
  
  def resource_options
    return  { 
      :only => safe_attributes, :include => 
      { 
        :properties => {:only => [:id, :name, :default_value, :is_private, :active]},
        :apps => {:only => [:id, :name]},
        :installed_components => 
        { 
          :only => [:id, :application_component_id, :application_environment_id, :updated_at],
          :include => 
          {
            :application_environment => {:include => { 
              :app => { :only => [ :id, :name, :app_version ] }, 
              :environment => { :only => [:id, :name] }
              } },
            :associated_current_property_values => { 
              :only => [:id, :value], :methods => [:name] 
            }, 
            :steps => { :only => [:id, :name, :aasm_state, :component_version, :version_tag_id] },
            :version_tags => { :only => [:id, :name] },
            :servers => { :only => [:id, :name, :dns, :ip_address, :os_platform] },
            :server_group => {:only => [:id, :name, :description ]}, 
            :server_aspect_groups => { :only => [:id, :name] },
            :server_aspects_through_groups => { :only => [:id, :name] }
         } 
        }
      }
    } 
  end
  
  def safe_attributes
    return [:name, :id, :active]
  end

end
