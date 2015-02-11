module AppImport
  class TemporaryPropertyValuesAttributes
    attr_reader :step, :xml_hash

    def initialize(step, xml_hash)
      @step = step
      @xml_hash = xml_hash
    end

    def import_app_request
      xml_hash['temporary_property_values'].each do |key|
        holder_type = key['original_value_holder_type']
        holder_name = key['holder_name']
        property_name= key['property_name']
        value = key['value']
        create_property_values(property_name, holder_type, holder_name, value, step)
      end
    end

    private

    def create_property_values(property_name, holder_type, holder_name, value, step)
      property_id = find_property_id(property_name)
      holder_id = find_original_value_holder(holder_type, holder_name, step)
      temp = TemporaryPropertyValue.new(property_id: property_id, original_value_holder_type: holder_type, original_value_holder_id: holder_id, step_id: step.id, request_id: step.request_id, value: value)
      temp.save
    end

    def find_original_value_holder(holder_type, holder_name, step)
      unless holder_type.nil?
        case holder_type
          when 'InstalledComponent'
            step.installed_component_id
          when 'Server'
            find_server(holder_name)
          when 'ApplicationPackage'
            find_application_package(holder_name, step)
          when 'PackageInstance'
            find_package_instance(holder_name)
          when 'ServerAspect'
            find_server_aspect(holder_name)
        end
      end
    end

    def find_server(holder_name)
      server = Server.find_by_name holder_name
      if server.present?
        server.id
      end
    end

    def find_application_package(holder_name, step)
      package = Package.find_by_name holder_name
      if package.present?
        appl_package = ApplicationPackage.find_by_package_id_and_app_id package.id, step.app_id
        if appl_package.present?
          appl_package.id
        end
      end
    end

    def find_package_instance(holder_name)
      package = PackageInstance.find_by_name holder_name
      if package.present?
        package.id
      end
    end

    def find_server_aspect(holder_name)
      aspect = ServerAspect.find_by_name holder_name
      if aspect.present?
        aspect.id
      end
    end

    def find_property_id(name)
      prop = Property.find_by_name name
      if prop.present?
        prop.id
      end
    end

  end
end