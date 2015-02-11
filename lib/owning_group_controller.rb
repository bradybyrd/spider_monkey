################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2013
# All Rights Reserved.
################################################################################

module OwningGroupController

  def self.included(base)
    base.before_filter :init_owning_group_data, :only => [:new, :create, :edit, :update]
  end

  private

  def init_owning_group_data
    if current_user.admin?
      @groups = Group.name_order
    else
      @groups = current_user.groups.name_order
    end
  end

end

