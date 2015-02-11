################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2013
# All Rights Reserved.
################################################################################

module ObjectStateHelper

  def display_object_state(object)
    render :partial => 'object_state/display_state', :locals => { :state_object => object }
  end

  def display_change_object_state_controls(object)
    render :partial => 'object_state/change_state', :locals => { :state_object => object }
  end

  def can_update_state?(object)
    if object.class.in? [Script, BladelogicScript]
      current_user.can?(:update_state, :automation)
    else
      current_user.can?(:update_state, object)
    end
  end

end
