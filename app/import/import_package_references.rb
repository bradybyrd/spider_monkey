class ImportPackageReferences

  def initialize(package_hash, package)
    @package_hash = package_hash
    @package = package
  end

  def import_references
    Array.wrap( @package_hash['references'] ).each do | reference_hash |
      server = Server.where( name: reference_hash['server']['name'] ).first
      if server.present?
        reference = import_reference(reference_hash, server )
        Array.wrap( reference_hash['property_values']).each do | prop_hash |
          import_reference_property_values( reference, prop_hash )
        end
      end
    end
  end

  private

  def import_reference(reference_hash, server)
    reference = @package.find_or_create_reference_named(reference_hash['name'])
    reference.server = server
    reference.resource_method = reference_hash['resource_method']
    reference.uri = reference_hash['uri']
    reference.save!
    reference
  end

  def import_reference_property_values(reference, prop_hash)
    Property.find_by_name(prop_hash['name']).update_value_for_object(reference, prop_hash['value'], true )
  end

end
