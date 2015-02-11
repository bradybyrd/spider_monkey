################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

class V1::EnvironmentPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :environment

  private

  def included_attributes
    {
        apps: {only: [:id, :name]},
        assigned_apps: {only: [:id, :name]},
        requests: {only: [:id, :name, :aasm_state]},
        servers: {only: [:id, :name]},
        server_groups: {only: [:id, :name]},
        installed_components: {
            only: [:id, :application_component_id, :application_environment_id, :location,
                   :version, :default_server_group_id, :reference_id],
            include: {
                component: {only: [:id, :name]},
                app: {only: [:id, :name]}
            }
        },
        environment_type: {only: [:id, :name, :description]},
        deployment_window_events: { only: [:id] },
        route_gates: {
            only: [:id, :description],
            include: {
                route: {only: [:id, :name, :route_type]}
            }
        }
    }
  end

  def resource_options
    { only: safe_attributes, include: included_attributes }
  end


  def safe_attributes
    [:id, :name, :default_server_group_id, :active, :deployment_policy, :default, :created_at, :updated_at]
  end

end
