################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::InstalledComponentPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :installed_component

  private

  def resource_options
    {
      only: safe_attributes,
      methods: [:current_associated_property_values],
      include: {
        application_component: {
          only: [:id, :updated_at],
          include: {
            app: {only: [:id, :name, :app_version]},
            component: {only: [:id, :name]}
          }
        },
        application_environment: {
          only: [:id, :updated_at],
          include: {environment: {only: [:id, :name]}}
        },
        associated_property_values: {
          only: [:id, :value],
          methods: [:name]
        },
        steps: { only: [:id, :name, :component_version, :aasm_state, :work_started_at, :work_finished_at, :manual, :position],
                 include: { request: { only: [:id, :name, :aasm_state, :scheduled_at, :target_completion_at, :started_at, :completed_at, :planned_at, :deleted_at, :created_at],
                                       include: { plan_member: { include: { plan: { only: [:id, :name] },
                                                                            stage: { only: [:id, :name] }}}}},
                            version_tag: { only: [:id, :name, :artifact_url] }}},
        version_tags: { only: [:id, :name] },
        servers: { only: [:id, :name, :dns, :ip_address, :os_platform] },
        server_group: { only: [:id, :name, :description] },
        server_aspect_groups: { only: [:id, :name] },
        server_aspects_through_groups: { only: [:id, :name] }
      }
    }
  end

  def safe_attributes
    [:name, :id, :version, :location, :default_server_group, :reference_id]
  end

end
