################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module ComponentsHelper

  def check_for_installed_comp(step, comp_name)
    installed_component = step.installed_component_only
    installed_component.present? ? installed_component_name(installed_component) : comp_name
  end


  def application_component_select_list(step, disable_fields)
  select_tag('step[component_id]',
             "<option value=''>Select</options>".html_safe +
               options_for_select(step_application_components_options(step, step.component_id)).html_safe,
             disabled: disable_fields,
             onmousedown: "if($.browser.msie){this.style.position='absolute';this.style.width='auto'}",
             onblur: "this.style.position='';this.style.width=''",
             onchange: "this.style.position='';this.style.width=''",
             title: step.component.try(:name),
             data: {protect_automation: step.protect_automation?}).html_safe
  end 

  def step_application_components_options(step, selected)
    apps_id = step.floating_procedure.apps.map(&:id)
    app_components_options = ''
    components = Component.components_for_apps(apps_id)
    components.each do |component|
      if component.id == selected
        app_components_options += "<option selected='selected' value='#{component.id}' title='#{component.name}' app_id='#{step.app_id}' component_id='#{component.id}' >#{component.name}</option>"
      else
        app_components_options += "<option value='#{component.id}' title='#{component.name}' app_id='#{step.app_id}' component_id='#{component.id}' >#{component.name}</option>"
      end
    end
    app_components_options
  end

end
