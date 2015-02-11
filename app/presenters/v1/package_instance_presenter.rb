class V1::PackageInstancePresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :package_instance
  
  private
  
  def resource_options
    return {
        :only => safe_attributes,
        :include => {
          :package => {
              :only => [:id, :name]
          },
          :property_values => {
              :only => [:id, :value],
              :methods => [:name]
          },
          :instance_references => {
              :only => [:id, :name, :url ],
              :include => {
                  :server => {
                      :only => [:id, :name]
                  },
                  :property_values => {
                      :only => [:id, :value],
                      :methods => [:name]
                  }
              }
          }
        }
    }
  end
  
  def safe_attributes
    return [:name, :id, :active ]
  end

end

