################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ServerAspectsHelper
  def server_property_value(property, server_aspect, display = false)
    return '' unless property
    (property.is_private && display) ? "-private-" : property.literal_value_for(server_aspect)
  end

  def render_server_aspects_tree(server_aspects, filter_proc = nil, *filter_args)
    server_aspects_for_render = filter_proc ? filter_proc.call(server_aspects, *filter_args) : server_aspects

    render :partial => 'server_aspects/tree', :locals => { :server_aspects => server_aspects_for_render, 
                                                           :filter_proc => filter_proc, 
                                                           :filter_args => filter_args }
  end

  def parent_options(grouped_parents, selected)
    grouped_parents.map do |level_name, servers| 
      content_tag :optgroup, options_from_collection_for_select(servers, :type_and_id, :path_string, selected), :label => ERB::Util.html_escape(level_name)
    end.join.html_safe
  end
end
