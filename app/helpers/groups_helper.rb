################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module GroupsHelper
  def link_to_name(group)
    if can?(:edit, group)
      link_to is_web(group.name), edit_group_path(group, page: params[:page], key: params[:key])
    else
      is_web(group.name)
    end
  end

  def empty_group_resources_parameter(entity_name = 'group', method_name = 'resources')
    hidden_field_tag "#{entity_name}[#{method_name}][]", [], multiple: true
  end

end
