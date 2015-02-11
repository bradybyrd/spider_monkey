################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::TeamGroupAppEnvRolePresenter < V1::AbstractPresenter

  presents :team_group_app_env_role

  private

  def resource_options
    { only: [:role_id], methods: [:team_id, :group_id, :app_id, :environment_id] }
  end
end

