class ImportPackageInstanceReferences

  def initialize(instance_hash, instance)
    @instance_hash = instance_hash
    @instance = instance
  end

  def import_instance_references
    Array.wrap(@instance_hash['instance_references']).each do |instance_reference_hash|
      reference = @instance.package.references.where(name: instance_reference_hash['reference']['name']).first
      server = Server.where(name: instance_reference_hash['server']['name']).first
      if reference.present? && server.present?
        instance_reference = import_instance_reference(instance_reference_hash, reference, server)
        Array.wrap(instance_reference_hash['property_values']).each do |prop_hash|
          import_instance_reference_property_values(instance_reference, prop_hash)
        end
      end
    end
  end

  private

  def import_instance_reference(instance_reference_hash, reference, server)
    instance_reference = @instance.find_or_initialize_reference_named(instance_reference_hash['name'])
    instance_reference.name = instance_reference_hash['name']
    instance_reference.uri = instance_reference_hash['uri']
    instance_reference.reference = reference
    instance_reference.server = server
    instance_reference.save!
    instance_reference
  end

  def import_instance_reference_property_values(instance_reference, prop_hash)
    Property.find_by_name(prop_hash['name']).update_value_for_object(instance_reference, prop_hash['value'], true )
  end

end
