################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2013
# All Rights Reserved.
################################################################################

module ObjectStateController
  include ObjectStateHelper

  def update_object_state
    object_find = "find_#{params[:controller].singularize}"
    object_find = object_find.gsub('/', '_')
    @object = send(object_find)
    @object.send(:"#{ params[:transition] }!") if can_update_state?(@object)
    if request.xhr?
      if params[:updater_method] == 'update_object_state'
        state_div = "\n<div id=\"state_indicator\">#{view_context.state_indicator_row(@object)}</div>\n"
      else
        state_div = "\n<div class=\"state_list\" id=\"state_list_#{params[:id]}\">#{view_context.state_list_row(@object)}</div>\n"
      end
      render text: state_div
    else
      render text: "Problem here ajax only", layout: false
    end
  end
end