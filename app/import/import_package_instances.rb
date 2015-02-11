class ImportPackageInstances

  def initialize(package_hash, package)
    @package_hash = package_hash
    @package = package
  end

  def import_instances
    Array.wrap(@package_hash['package_instances']).each do |instance_hash|
      instance = import_instance(instance_hash)
      import_reference_property_values(instance, instance_hash)
      ImportPackageInstanceReferences.new(instance_hash, instance).import_instance_references
    end
  end

  private

  def import_reference_property_values(instance, instance_hash)
    Array.wrap(instance_hash['property_values']).each do |prop_hash|
      import_reference_property_value(instance, prop_hash)
    end
  end

  def import_instance(instance_hash)
    instance = @package.find_or_initialize_instance_named(instance_hash['name'])
    instance.name = instance_hash['name']
    instance.active = true
    if instance.new_record?
      @package.increment_next_instance_number
      @package.save!
    end
    instance.save!
    instance
  end

  def import_reference_property_value(instance, prop_hash)
    Property.find_by_name(prop_hash['name']).update_value_for_object(instance, prop_hash['value'], true)
  end

end
