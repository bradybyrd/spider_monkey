################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module PropertiesHelper
  def field_disabled_on_step_creation?(work_task, property)
    !property.entry_during_step_creation_on_work_task?(work_task)
  end

  def property_value_input(name, property, current_value, html_options = {})
    html_options[:id] ||= "#{name.gsub(/\W+/, '_')}_#{property.id}"

    markup = "<div class='property_label' >" #style='width:auto;'>"
    markup << "<label for=\"#{html_options[:id]}\" style='float:left'>#{h property.name}</label></div>"
    markup << property_value_input_field(name, property, current_value, html_options)

    markup.html_safe
  end

  def property_value_label(name, property, current_value, html_options = {})
    html_options[:id] ||= "#{name.gsub(/\W+/, '_')}_#{property.id}"

    markup = "<div class='property_label' >" #style='width:auto;'>"
    markup << "<label for=\"#{html_options[:id]}\" style='float:left'>#{h property.name}</label>"

    html_options.merge! :style => "float:right;clear:none"
    markup << property_value_label_field(name, property, current_value, html_options)
    markup << "</div>"
    markup.html_safe
  end


  def property_value_input_field(name, property, current_value, html_options = {})
    if property.multiple_default_values?
      current_value_list = current_value.include?(",") ? current_value.split(/\s*,\s*/, -1) : property.default_values
      select_tag("#{name}[#{property.id}]", options_for_select(current_value_list, current_value_list), html_options)
    else
      if property.is_private?
        password_field_tag("#{name}[#{property.id}]", current_value, html_options)
      else
        text_field_tag("#{name}[#{property.id}]", current_value, html_options)
      end
    end
  end

  def property_value_label_field(name, property, current_value, html_options = {})
    if property.is_private?
      label_tag("#{name}[#{property.id}]", "********", html_options)
    else
      label_tag("#{name}[#{property.name}]", current_value, html_options)
    end
  end

  def property_value_in_place_input(name, property, current_value, html_options = {})
    html_options[:id] ||= "#{name.gsub(/\W+/, '_')}_#{property.id}"
    property_value_input_field(name, property, current_value, html_options)
  end

  def show_hide_buttons
    markup = image_tag('icons/lock_delete.png', :class => 'show_hide_button', :alt => 'Click to lock')
    markup << image_tag('icons/lock.png', :class => 'show_hide_button', :style => 'display: none', :alt => 'Click to unlock')
  end

  def as_key_value_string(property_value_holder)
    property_value_holder.property_values.map { |pv| h "#{pv.property.name}=#{pv.decorate.value}" }.to_sentence
  end

end
