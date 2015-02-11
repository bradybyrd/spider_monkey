class Package < ActiveRecord::Base


  def self.import_app(packages_list_xml_array, app)
    packages_list_xml_array.each do |package_hash|
      package = create_package(package_hash)
      app_package = add_package_to_app(package, app)
      add_package_properties(app_package, package_hash["properties"])
      ImportPackageReferences.new(package_hash, package).import_references
      ImportPackageInstances.new(package_hash, package).import_instances
    end
  end

  def self.import_app_request(step, xml_hash)
    if xml_hash["package"]
      package = find_by_name  xml_hash["package"]["name"]
      if package.present?
        step.package_id = package.id
        step.related_object_type = 'package'
      end
    end
  end

  private

  def self.create_package(package_hash)
    package = find_or_initialize_by_name(package_hash["name"])
    package.instance_name_format = package_hash["instance_name_format"]
    package.active = true
    package.save!
    package
  end

  def self.add_package_to_app(package, app)
    if !app.package_ids.include?(package.id)
      app_package = app.application_packages.create!(package_id: package.id)
    else
      app_package = ApplicationPackage.by_application_and_package_names(app.name, package.name).first
    end
    app_package
  end

  def self.add_package_properties(app_package, properties)
    Array.wrap(properties).each do |property_hash|
      prop = create_property_from_hash(property_hash)
      add_property_to_package(prop, app_package)
    end
  end

  def self.add_property_to_package(prop, app_package)
    if prop
      pcids = prop.package_ids
      pcids << app_package.package.id unless pcids.include?(app_package.package.id)
      prop.update_attributes!({:package_ids => pcids})
    end
  end

  def self.create_property_from_hash(propkey)
    prop = Property.find_or_initialize_by_name(propkey["name"])
    prop.default_value = propkey["default_value"]
    prop.active = propkey["active"]
    prop.is_private = propkey["is_private"]
    prop.save!
    prop
  end
end
