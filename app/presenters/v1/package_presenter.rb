class V1::PackagePresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :package

  private

  def resource_options
    {
      only: safe_attributes, include: {
      applications: { only: [:id, :name] },
      properties:   { only: [:id, :name, :default_value, :is_private, :active] },
      references:   { only:    [:id, :name],
                      include: {
                        property_values: {
                          only:    [:id, :value],
                          methods: [:name]
                        }
                      }
      },
    }
    }
  end

  def safe_attributes
    [:name, :id, :active, :next_instance_number, :instance_name_format]
  end

end
