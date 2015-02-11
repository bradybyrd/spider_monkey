class V1::PackageInstancesPresenter < V1::AbstractPresenter

  presents :package_instances

  private

  def resource_options
    {
      only: safe_attributes,
      include: {
        package: {
          only: [:id, :name]
        },
        property_values: {
          only: [:id, :value, :property_id],
          methods: [:name]
        },
        instance_references: {
          only: [:id, :name, :url],
          include: {
            server: {
              only: [:id, :name]
            }
          }
        }
      }
    }
  end

  def safe_attributes
    [:name, :id, :active]
  end

end

