################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2013
# All Rights Reserved.
################################################################################

module OwningGroupHelper

  def display_owning_group(object)
    render :partial => 'owning_group/display', :locals => { :object => object }
  end

  def drop_down_for_owning_group(object, f)
    render :partial => 'owning_group/change', :locals => { :object => object, :f => f }
  end
end
