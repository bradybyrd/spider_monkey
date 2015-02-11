################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module SharedScriptArgument

  def self.included(klass)
    klass.has_many :script_argument_to_property_maps, :as => 'script_argument', :dependent => :destroy

    klass.has_many :properties, :through => :script_argument_to_property_maps, :uniq => true do
      def for(model)
        self.all(:conditions => ["#{ScriptArgumentToPropertyMap.quoted_table_name}.value_holder_id = ? AND 
                                 #{ScriptArgumentToPropertyMap.quoted_table_name}.value_holder_type = ?", 
                                 model.id, model.class.to_s])
      end
    end
  end

  def app_mappings?
    !app_mappings.empty?
  end

  def infrastructure_mappings?
    !infrastructure_mappings.empty?
  end

  def app_mappings
    script_argument_to_property_maps.for_components
  end

  def infrastructure_mappings
    script_argument_to_property_maps.for_servers + script_argument_to_property_maps.for_server_aspects
  end

  def app_mapping_property_ids
    app_mappings.map { |mapping| mapping.property_id }
  end

  def app_mapping_component_ids
    app_mappings.map { |mapping| mapping.component_id }
  end

  def app_mapping_application_environment_ids
    app_mappings.map { |mapping| mapping.application_environment_id }
  end

  def app_mapping_app_ids
    app_mappings.map { |mapping| mapping.app_id }
  end

  def infrastructure_mapping_property_ids
    infrastructure_mappings.map { |mapping| mapping.property_id }
  end

  def infrastructure_mapping_server_ids
    script_argument_to_property_maps.for_servers.map { |mapping| mapping.server_id }
  end

  def infrastructure_mapping_server_aspect_ids
    script_argument_to_property_maps.for_server_aspects.map { |mapping| mapping.server_aspect_id }
  end

  def values_from_properties(value_holder)
    return [] unless value_holder
    values = properties.for(value_holder).map { |property| property.literal_value_for(value_holder) }
    value_holder.server_associations.each { |assoc| values += values_from_properties(assoc) } if value_holder.is_a? InstalledComponent
    #logger.info "SS__ SA_ValuesFromProps: #{values.inspect}"
    values
  end

  def update_script_argument_to_property_maps(new_properties, new_value_holders)
    script_argument_to_property_maps.clear

    new_value_holders.each do |value_holder|
      new_properties.each do |property|
        next unless value_holder.properties.include? property
        script_argument_to_property_maps.create!(:property => property, :value_holder => value_holder)
      end
    end

    reload
  end
  
  def group_app_mappings
    script_arguments_arr = []
    script_arg = app_mappings.group_by(&:property_id).each  {|key, val|
      script_arguments_arr << val.first
    }
    script_arguments_arr.flatten!
    script_arguments_arr
  end

end
