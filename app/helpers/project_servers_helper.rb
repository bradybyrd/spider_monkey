################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ProjectServersHelper
  def can_manage_project?(integration_project)
    can?(:create, integration_project) ||
        can?(:edit, integration_project) ||
        can?(:make_active_inactive, integration_project)
  end
end
