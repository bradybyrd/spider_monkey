################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
require 'permission_manager'

class Ability

  include CanCan::Ability

  def initialize(user)
    user = User.admins.first if user.nil? # trap for rest
    if user.root?
      can :manage, :all
    else
      PermissionManager.new(self, user).apply_permissions
    end
  end
end
