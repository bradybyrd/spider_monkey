################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::GroupsPresenter < V1::AbstractPresenter
  presents :groups

  private

  def resource_options
    { only: safe_attributes,
      include:
      {
        steps: { only: [:id, :name] },
        resources: { only: [:id, :login, :email, :first_name, :last_name] },
        roles: { only: [:id, :name] },
        placeholder_resources: { only: [:id, :login, :email, :first_name, :last_name] },
        teams: { only: [:id, :name] }
      }
    }
  end

  def safe_attributes
    [:id, :name, :email, :position, :created_at, :updated_at, :active]
  end
end
