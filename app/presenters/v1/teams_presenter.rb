################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::TeamsPresenter < V1::AbstractPresenter

  presents :teams

  private

  def resource_options
    {
      only: safe_attributes, include: {
        apps: { only: [:id, :name] },
        assigned_apps: { only: [:id, :name] },
        users: { only: [:id, :login, :email, :first_name, :last_name, :active] },
        groups: { only: [:id, :name, :active, :email] },
        team_group_app_env_roles: { only: [:role_id], methods: [:team_id, :group_id, :app_id, :environment_id] }
      }
    }
  end


  def safe_attributes
    [:id, :name, :user_id, :active, :created_at, :updated_at]
  end

end
