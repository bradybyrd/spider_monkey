################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CsvImporter
  def self.import_component_properties!(csv_data)
    ActiveRecord::Base.transaction do
      CSV.parse(csv_data) do |row|
        app = App.find_or_create_by_name row[0]
        environment = Environment.find_or_create_by_name row[1]
        app_env = ApplicationEnvironment.find_or_create_by_app_id_and_environment_id app.id, environment.id

        property_count = 0
        row[2..-1].each do |col|
          if property_count == 0
            component_pieces = col.match /^([^:]+)(?::(\d+))?$/
            component_name = component_pieces[1]
            property_count = component_pieces[2].to_i

            @component = Component.find_or_create_by_name component_name
            app_comp = ApplicationComponent.find_or_create_by_app_id_and_component_id app.id, @component.id
            @inst_comp = InstalledComponent.find_or_create_by_application_environment_id_and_application_component_id(app_env.id, app_comp.id)
          else
            property_pieces = col.match /^([^:]+)(?::(.*))?$/
            property_name = property_pieces[1]
            property_value = property_pieces[2]

            property = Property.find_or_create_by_name(property_name)
            @component.properties << property unless @component.property_ids.include? property.id

            if property_value

              if property_value.gsub!(/^:/, '')
                if property.default_value
                  unless property.default_values.include?(property_value.strip)
                    property.update_attributes(:default_value => "#{property.default_value}, #{property_value}")
                  end
                else
                  property.update_attributes(:default_value => "#{property_value}")
                end
              end

              property.property_values.find_or_create_by_installed_component_id_and_value(@inst_comp.id, property_value)
            end

            property_count -= 1
          end
        end
      end
    end
  end
end
