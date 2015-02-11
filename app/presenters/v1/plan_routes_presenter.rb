################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class V1::PlanRoutesPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :plan_routes

  private

  def resource_options
    return {only: safe_attributes, include: {
        plan: {only: [:id, :name], include: {
            plan_template: {only: [:id, :name]}
          }
        },
        route: {only: [:id, :name, :description, :route_type], include: {
            app: {only: [:id, :name]}
          }
        }
      }
    }
  end

  def safe_attributes
    return [:id, :created_at, :updated_at]
  end

end
