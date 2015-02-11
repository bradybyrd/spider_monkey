################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::InstalledComponentsPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :components

  private

  def resource_options
    {
      only: safe_attributes,
      include: {
        application_component: {
          only: [:id, :updated_at],
          include: {
            app: { only: [:id, :name, :app_version] },
            component: { only: [:id, :name] }
          }
        },
        application_environment: {
          only: [:id, :updated_at],
          include: {
            environment: { only: [:id, :name] }
          }
        }
      }
    }
  end

  def safe_attributes
    [:name, :id, :version, :location, :default_server_group, :reference_id]
  end

end