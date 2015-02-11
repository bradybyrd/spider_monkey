################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module InstalledComponentsHelper
  
  def installed_component_name(installed_component)
    installed_component.reference ? "<i>#{h installed_component.name}</i>".html_safe : h(installed_component.name)
  end


  def selected_server_association_type(installed_component, server_levels)
    if installed_component.default_server_group_id
      return 'server_group'
    elsif installed_component.server_aspect_group_ids.any?
      return 'server_aspect_group'
    elsif installed_component.server_aspect_ids && server_levels
      selected_server_level = server_levels.find do |sl|      
        sl.server_aspects.all.any? do |sa| # true if any server_aspects exist for component
          installed_component.server_aspect_ids.any?{|ic_sid| ic_sid == sa.id}
        end
      end
      if selected_server_level
        return "server_level_#{selected_server_level.id}"
      end
    end

    'server'
  end
end
