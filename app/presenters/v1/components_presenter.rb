class V1::ComponentsPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :components
  
  private
  
  def resource_options
    return { :only => safe_attributes, :include => { 
      :apps => {:only => [:id, :name]},
      :installed_components => { :only => [:id, :application_component_id, :application_environment_id, :updated_at], 
      :include => {:find_properties => {:only => [:id, :value], :methods => [:name]}, 
                    :version_tags => {:only => [:id, :name]},
                    :application_environment => { :only => [:id, :environment_id] },
                    :application_component => { :only => [:id, :app_id, :component_id] } } }
      }  }   
  end
  
  def safe_attributes
    return [:name, :id, :active]
  end

end