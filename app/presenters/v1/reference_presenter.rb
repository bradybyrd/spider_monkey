class V1::ReferencePresenter < V1::AbstractPresenter
  presents :reference

  private

  def resource_options
    { :only => safe_attributes,
      :include => {
        property_values: property_value_attributes
      }
    }
  end

  def property_value_attributes
    {
      only: [:id, :value],
      methods: [:name]
    }
  end

  def safe_attributes
    [
      :id,
      :name,
      :server_id,
      :package_id,
      :uri,
      :resource_method,
      :created_at,
      :updated_at,
    ]
  end
end
