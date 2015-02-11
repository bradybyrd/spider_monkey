################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module BladelogicScriptsHelper

  def bladelogic_script_argument_value_input_display(step, argument, installed_component, value = nil)

    input_div = '<div class="field">'
#    if (argument.is_a?(ScriptArgument) || argument.is_a?(CapistranoScriptArgument)) && argument.choices.present?
    if argument.choices.present?
      input_div << bladelogic_script_argument_value_select_tag(step, argument, installed_component, value)
    else
      input_div << bladelogic_script_argument_value_input_tag(step, argument, installed_component, value)
    end
    if !argument.is_a?(ScriptArgument) && bladelogic_should_include_select_tag?(argument, installed_component)
      values = argument.values_from_properties(installed_component)
      input_div << select_tag("script_argument_values_#{argument.id}", options_for_select(values), :include_blank => true, :class => 'script_argument_values')
    end
    input_div << "</div>"
    input_div.html_safe
  end

  def bladelogic_script_argument_value_select_tag(step, argument, installed_component, value = nil)
    value ||= bladelogic_script_argument_value_input_tag_value(step, argument, installed_component)
    select_tag("argument[#{argument.id}]",
      options_for_select(argument.choices, value),
      :id => dom_id(argument), :class => "step_script_argument")
  end

  def bladelogic_should_include_select_tag?(argument, installed_component)
    argument.values_from_properties(installed_component).size >= 2
  end

  def bladelogic_script_argument_value_input_tag(step, argument, installed_component, value = nil)
    value ||= bladelogic_script_argument_value_input_tag_value(step, argument, installed_component)
    if argument.is_private
      password_field_tag "argument[#{argument.id}]", value, :id => dom_id(argument), :class => "step_script_argument"
    else
      text_field_tag "argument[#{argument.id}]", value, :id => dom_id(argument), :class => "step_script_argument"
    end
  end

  def bladelogic_script_argument_value_input_tag_value(step, argument, installed_component, options = {})
    if step
      step_value = step.script_argument_property_value(argument, options)
      return step_value unless step_value.blank?
    end
    values_from_properties = argument.values_from_properties(installed_component)
    return values_from_properties.first if values_from_properties.size == 1
  end

end
