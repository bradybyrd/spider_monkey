################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module MapsHelper

  def property_value(app_env, component, property)
    installed_component = app_env.installed_component_for(component)

    if installed_component 
      property_value = installed_component.literal_property_value_for(property)

      field_value = ensure_space property_value
      
      # check if it is private and mask it
      field_value = PropertyValue::MASK_CHARACTER * field_value.size if property.is_private?
      
      field_value = "<em>#{field_value}</em>" if property.static_for? installed_component.app
      field_value
    else
      ensure_space
    end
  end
  
  # This is added to display the full value on Rollover without <em> tag
  def property_value_title(app_env, component, property)
    installed_component = app_env.installed_component_for(component)

    if installed_component 
      property_value = installed_component.literal_property_value_for(property)

      field_value = ensure_space property_value
      # check if it is private and mask it
      field_value = PropertyValue::MASK_CHARACTER * field_value.size if property.is_private?
      field_value
    else
      ensure_space
    end
  end

  def property_value_change_dates(app_env, components)
    installed_components = components.map { |comp| app_env.installed_component_for(comp) }.compact

    installed_components.map { |installed_comp| installed_comp.property_values.all(:order => 'created_at DESC').map { |val| val.created_at } }.flatten.uniq 
  end

  def date_dom_id(date)
    date.strftime("%Y%m%d%H%M")
  end

  def servers_on_steps(steps)
    return unless steps

    steps.map { |step| step.server.name if step.server }.compact.uniq.to_sentence
  end

  def components_on_steps(steps)
    return unless steps

    steps.map { |step| step.component.name }.uniq.to_sentence
  end

  def print_component_level(level_number, component_level, component)
    if component == component_level.first
      level_number
    else
      '&nbsp;'
    end
  end

  def print_installed_component_version(installed_component)
    if installed_component && !installed_component.version.blank?
      h(installed_component.version)
    else
      '&nbsp;'
    end
  end

end
