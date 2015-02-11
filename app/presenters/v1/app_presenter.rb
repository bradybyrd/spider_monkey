################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::AppPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :app

  private

  def resource_options
    { only: safe_attributes,
      include: {
        requests: { only: [:id, :name] },
        steps: { only: [:id, :name] },
        environments: { only: [:id, :name] },
        components: { only: [:id, :name] },
        installed_components: { only: [:id, :name, :environment_id, :component_id] },
        teams: { only: [:id, :name] },
        users: { only: [:id, :login, :email, :last_name, :first_name] },
        tickets: { only: [:id, :name, :foreign_id, :status, :ticket_type, :project_server_id] },
        routes: {
          only: [:id, :name, :route_type],
          include: {
            route_gates: { only: [:id, :description] }
          }
        }
      }
    }
  end

  def safe_attributes
    [:id, :name, :app_version, :active, :default, :created_at, :updated_at]
  end
end
