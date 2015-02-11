class ApplicationPackage < ActiveRecord::Base

  def self.import_app(list_xml_array, app)
    list_xml_array.each do |application_package_hash|
      package = Package.find_by_name(application_package_hash["package"]["name"])
      application_package = app.application_packages.where(package_id: package).first
      import_property_values(application_package, application_package_hash)
    end
  end

  private

  def self.import_property_values(application_package, application_package_hash)
    Array.wrap(application_package_hash["property_values"]).each do |application_package_value_hash|
      import_property_value(application_package, application_package_value_hash)
    end
  end

  def self.import_property_value(application_package, prop_hash)
    Property.find_by_name(prop_hash["name"]).update_value_for_object(application_package, prop_hash["value"], true)
  end

end
